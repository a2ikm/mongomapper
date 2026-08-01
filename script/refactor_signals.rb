# frozen_string_literal: true

# Builds a constant-based dependency graph of lib/**/*.rb and emits refactor
# signals as JSON on STDOUT:
#
#   * fan_in / fan_out per file (and fan_in * fan_out as a "god object" score)
#   * strongly connected components of size >= 2 (circular dependencies)
#   * total line count per file ("files you dread opening")
#   * deep method chains (Law of Demeter / train-wreck violations)
#
# Why constant-based instead of scanning require/require_relative lines:
# MongoMapper mixes `require`, `require_relative` and `autoload` with
# $LOAD_PATH-relative string paths, so a require-line scan leaves holes in the
# graph. Instead we record where each constant is *defined* (class/module
# bodies, `autoload`, constant assignment) and where each file *references* a
# constant, then draw an edge A -> B when A references a constant defined in B.
# This mirrors the path Ruby's constant resolution actually takes, regardless
# of how the file happens to be required.
#
# Accuracy note: full Ruby lexical-scope resolution is expensive to reproduce.
# Since these numbers only drive a ranking (not correctness), we resolve a
# reference by trying the enclosing namespaces first and fall back to a
# suffix match. Good enough to surface hotspots.

require "prism"
require "pathname"
require "tsort"
require "json"

LIB = Pathname.new("lib")
DEMETER_MIN_DEPTH = 3 # a.b.c.d and deeper counts as a train wreck

files = Dir.glob("lib/**/*.rb").sort

const_to_file = {} # "MongoMapper::Plugins::Keys" => "lib/mongo_mapper/plugins/keys.rb"
file_refs = Hash.new { |h, k| h[k] = [] } # file => [[const_name, namespace_stack], ...]
file_lines = {}
demeter = []

# Render a ConstantReadNode / ConstantPathNode as a dotted string, e.g.
# "Plugins::Keys". Returns nil for dynamic paths we can't statically resolve.
def const_name(node)
  case node
  when Prism::ConstantReadNode
    node.name.to_s
  when Prism::ConstantPathNode
    parent = node.parent ? const_name(node.parent) : nil
    [parent, node.name.to_s].compact.join("::")
  end
end

# A "navigational" send is a dotted call to a word-named method, e.g. `a.b`.
# Operators (`+`, `==`), index (`[]`) and implicit-self calls don't count as
# Demeter navigation, so we exclude them to avoid false train-wreck reports.
def navigational?(node)
  return false unless node.is_a?(Prism::CallNode)
  return false if node.call_operator_loc.nil? # operator or implicit-self call

  node.name.to_s.match?(/\A[A-Za-z_]\w*[?!]?\z/)
end

# Length of a trailing chain of navigational sends, e.g. `a.b.c.d` => 3.
# Used to flag Law of Demeter violations.
def chain_depth(node)
  return 0 unless navigational?(node)

  depth = 1
  cur = node.receiver
  while navigational?(cur)
    depth += 1
    cur = cur.receiver
  end
  depth
end

files.each do |file|
  source = File.read(file)
  file_lines[file] = source.count("\n") + (source.empty? || source.end_with?("\n") ? 0 : 1)

  result = Prism.parse(source)
  ns_stack = []

  walk = lambda do |node|
    return unless node

    case node
    when Prism::ModuleNode, Prism::ClassNode
      name = const_name(node.constant_path)
      full = (ns_stack + [name]).compact.join("::")
      const_to_file[full] ||= file
      # A subclass references its superclass; record that before descending.
      if node.is_a?(Prism::ClassNode) && node.superclass
        walk.call(node.superclass)
      end
      ns_stack.push(name)
      walk.call(node.body) if node.body
      ns_stack.pop
    when Prism::ConstantWriteNode
      # e.g. `Foo = Class.new` — treat as a definition of Foo in this file.
      full = (ns_stack + [node.name.to_s]).compact.join("::")
      const_to_file[full] ||= file
      walk.call(node.value)
    when Prism::CallNode
      if node.name == :autoload && node.arguments && node.arguments.arguments.size == 2
        sym, path = node.arguments.arguments
        if sym.is_a?(Prism::SymbolNode) && path.is_a?(Prism::StringNode)
          full = (ns_stack + [sym.unescaped]).compact.join("::")
          resolved = (LIB + "#{path.unescaped}.rb").cleanpath.to_s
          const_to_file[full] = resolved if File.exist?(resolved)
        end
      end

      if (d = chain_depth(node)) >= DEMETER_MIN_DEPTH
        demeter << {
          "file" => file,
          "line" => node.location.start_line,
          "depth" => d,
          "snippet" => node.slice.gsub(/\s+/, " ")[0, 100],
        }
      end

      node.compact_child_nodes.each { |c| walk.call(c) }
    when Prism::ConstantReadNode, Prism::ConstantPathNode
      name = const_name(node)
      file_refs[file] << [name, ns_stack.dup] if name
      # Do not descend: we recorded the whole path already.
    else
      node.compact_child_nodes.each { |c| walk.call(c) }
    end
  end

  walk.call(result.value)
end

# Resolve a referenced constant name (as seen inside `ns`) to a defining file.
def resolve(name, ns, const_to_file)
  # Try the reference qualified by each enclosing namespace, innermost first.
  parts = ns.dup
  loop do
    cand = (parts + [name]).join("::")
    return const_to_file[cand] if const_to_file[cand]
    break if parts.empty?
    parts.pop
  end
  return const_to_file[name] if const_to_file[name]

  # Suffix fallback: any defined constant ending in ::name. Prefer the match
  # with the fewest namespace segments to reduce noise.
  matches = const_to_file.keys.select { |k| k == name || k.end_with?("::#{name}") }
  best = matches.min_by { |k| [k.count(":"), k.length] }
  best && const_to_file[best]
end

fan_out = Hash.new { |h, k| h[k] = [] } # file => Set-ish array of target files
fan_in  = Hash.new { |h, k| h[k] = [] }
edges = []

file_refs.each do |file, refs|
  targets = []
  refs.each do |(name, ns)|
    target = resolve(name, ns, const_to_file)
    next unless target
    next unless files.include?(target)
    next if target == file

    targets << target
  end
  targets.uniq.each do |target|
    fan_out[file] << target
    fan_in[target] << file
    edges << [file, target]
  end
end

# Strongly connected components (circular dependency clusters).
class Graph
  include TSort

  def initialize(nodes, edges)
    @nodes = nodes
    @succ = Hash.new { |h, k| h[k] = [] }
    edges.each { |a, b| @succ[a] << b }
  end

  def tsort_each_node(&blk)
    @nodes.each(&blk)
  end

  def tsort_each_child(node, &blk)
    @succ[node].uniq.each(&blk)
  end
end

graph = Graph.new(files, edges)
cycles = graph.each_strongly_connected_component.select { |c| c.size >= 2 }

files_out = {}
files.each do |file|
  fi = fan_in[file].uniq.size
  fo = fan_out[file].uniq.size
  files_out[file] = {
    "lines" => file_lines[file] || 0,
    "fan_in" => fi,
    "fan_out" => fo,
    "score" => fi * fo,
  }
end

# A deeper chain visits its inner sub-chains too; keep only the deepest per
# source line so a single train wreck is reported once.
demeter = demeter
  .group_by { |d| [d["file"], d["line"]] }
  .map { |_, group| group.max_by { |d| d["depth"] } }
demeter.sort_by! { |d| -d["depth"] }

puts JSON.pretty_generate(
  "files" => files_out,
  "cycles" => cycles,
  "demeter" => demeter,
  "edges" => edges.uniq,
)
