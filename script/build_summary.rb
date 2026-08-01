# frozen_string_literal: true

# Combines the RuboCop metrics JSON (script's .rubocop_metrics.yml run) and the
# dependency-graph JSON (script/refactor_signals.rb) into a refactor-signal
# report.
#
# Usage:
#   ruby script/build_summary.rb rubocop.json deps.json
#
# Output:
#   * A Markdown report appended to $GITHUB_STEP_SUMMARY (or STDOUT when the
#     env var is unset, e.g. running locally).
#   * `::warning file=...,line=...::` annotations on STDOUT for the few worst
#     offenders, so they also surface on the PR diff. We deliberately annotate
#     only a handful to avoid alert fatigue.

require "json"

rubocop_path, deps_path = ARGV
abort "usage: build_summary.rb <rubocop.json> <deps.json>" unless rubocop_path && deps_path

rubocop = JSON.parse(File.read(rubocop_path))
deps = JSON.parse(File.read(deps_path))

TOP_N = 10          # rows per table
ANNOTATE_N = 5      # annotations per signal

# --- Parse RuboCop metric offenses -----------------------------------------
# Every metric cop runs with Max: 0, so each offense message embeds the real
# value as `[<a, b, c> 3.0/0]` (AbcSize) or `[184/0]` (lengths).
VALUE_RE = /\[(?:<[^>]*>\s*)?([\d.]+)\/\d+\]/
NAME_RE = /`([^`]+)`/

abc = []        # {file, line, name, value}
method_len = [] # {file, line, name, value}
type_len = []   # {file, line, name, value} for Class/ModuleLength

(rubocop["files"] || []).each do |f|
  path = f["path"]
  (f["offenses"] || []).each do |o|
    m = o["message"].match(VALUE_RE)
    next unless m

    rec = {
      file: path,
      line: o.dig("location", "line") || o.dig("location", "start_line") || 1,
      name: o["message"][NAME_RE, 1] || File.basename(path),
      value: m[1].to_f,
    }
    case o["cop_name"]
    when "Metrics/AbcSize"      then abc << rec
    when "Metrics/MethodLength" then method_len << rec
    when "Metrics/ClassLength", "Metrics/ModuleLength" then type_len << rec
    end
  end
end

abc.sort_by! { |r| -r[:value] }
type_len.sort_by! { |r| -r[:value] }

# Highest ABC score per file, for the combined ranking.
abc_by_file = abc.group_by { |r| r[:file] }.transform_values { |rs| rs.first[:value] }

# --- Dependency-graph signals ----------------------------------------------
files = deps["files"] || {}
cycles = deps["cycles"] || []
churn_commits = deps["churn_commits"]

by_lines = files.sort_by { |_, v| -v["lines"] }
by_coupling = files.sort_by { |_, v| -v["score"] }
by_churn = files.sort_by { |_, v| -(v["churn"] || 0) }

# --- Combined hotspot ranking ----------------------------------------------
# "Structural badness" is the normalized sum of intrinsic complexity (file
# length, peak ABC) and centrality (fan-in×fan-out). We then modulate it by
# churn, because a hotspot is complexity that actually changes often
# (badness × churn). A CHURN_FLOOR keeps complex-but-stable files visible
# rather than zeroing them, and makes the ranking degrade gracefully to the
# pure-complexity order when churn data is absent (e.g. a shallow checkout).
CHURN_FLOOR = 0.25

max_lines = files.map { |_, v| v["lines"] }.max.to_f
max_coupling = files.map { |_, v| v["score"] }.max.to_f
max_churn = files.map { |_, v| v["churn"] || 0 }.max.to_f
max_abc = abc_by_file.values.max.to_f

norm = lambda { |value, max| max.positive? ? value / max : 0.0 }

combined = files.map do |path, v|
  badness =
    norm.call(v["lines"], max_lines) +
    norm.call(v["score"], max_coupling) +
    norm.call(abc_by_file[path].to_f, max_abc)
  churn_factor = CHURN_FLOOR + (1.0 - CHURN_FLOOR) * norm.call(v["churn"] || 0, max_churn)
  {
    file: path,
    score: badness * churn_factor,
    lines: v["lines"],
    coupling: v["score"],
    fan_in: v["fan_in"],
    fan_out: v["fan_out"],
    abc: abc_by_file[path],
    churn: v["churn"] || 0,
  }
end
combined.sort_by! { |r| -r[:score] }

# --- Render Markdown --------------------------------------------------------
def short(path)
  path.sub(%r{\Alib/}, "")
end

out = +""
out << "## 🔍 Refactor signals\n\n"
out << "Ranking of likely refactor hotspots. Signals are advisory only — nothing here fails the build.\n\n"

out << "### 🏆 Top hotspots (combined score)\n\n"
churn_note = churn_commits ? " over the last #{churn_commits} commits" : ""
out << "Structural badness (file length + fan-in×fan-out + peak ABC), modulated by churn#{churn_note}.\n\n"
out << "| # | File | Score | Lines | fan-in×out | Peak ABC | Churn |\n"
out << "|---|------|------:|------:|-----------:|---------:|------:|\n"
combined.first(TOP_N).each_with_index do |r, i|
  out << format(
    "| %d | `%s` | %.2f | %d | %d (%d×%d) | %s | %d |\n",
    i + 1, short(r[:file]), r[:score], r[:lines], r[:coupling], r[:fan_in], r[:fan_out],
    r[:abc] ? format("%.1f", r[:abc]) : "–", r[:churn]
  )
end

out << "\n<details><summary>Per-signal breakdown</summary>\n\n"

unless abc.empty?
  out << "#### 🧮 Highest ABC size (hard-to-read methods)\n\n"
  out << "| Method | ABC | Location |\n|---|---:|---|\n"
  abc.first(TOP_N).each do |r|
    out << format("| `%s` | %.1f | `%s:%d` |\n", r[:name], r[:value], short(r[:file]), r[:line])
  end
  out << "\n"
end

unless by_lines.empty?
  out << "#### 📏 Longest files\n\n"
  out << "| File | Lines |\n|---|---:|\n"
  by_lines.first(TOP_N).each do |path, v|
    out << format("| `%s` | %d |\n", short(path), v["lines"])
  end
  out << "\n"
end

if by_coupling.any? { |_, v| v["score"].positive? }
  out << "#### 🕸️ Highest fan-in × fan-out (god objects)\n\n"
  out << "| File | fan-in×out | fan-in | fan-out |\n|---|---:|---:|---:|\n"
  by_coupling.first(TOP_N).each do |path, v|
    next unless v["score"].positive?

    out << format("| `%s` | %d | %d | %d |\n", short(path), v["score"], v["fan_in"], v["fan_out"])
  end
  out << "\n"
end

unless cycles.empty?
  out << "#### 🔁 Circular dependencies\n\n"
  cycles.each do |cycle|
    out << "- " << cycle.map { |p| "`#{short(p)}`" }.join(" → ") << "\n"
  end
  out << "\n"
end

if by_churn.any? { |_, v| (v["churn"] || 0).positive? }
  label = churn_commits ? "last #{churn_commits} commits" : "recent commits"
  out << "#### 🔥 Most-churned files (#{label})\n\n"
  out << "Frequently changed on its own means little — read alongside complexity above.\n\n"
  out << "| File | Churn |\n|---|---:|\n"
  by_churn.first(TOP_N).each do |path, v|
    next unless (v["churn"] || 0).positive?

    out << format("| `%s` | %d |\n", short(path), v["churn"])
  end
  out << "\n"
end

out << "</details>\n"

summary_file = ENV["GITHUB_STEP_SUMMARY"]
if summary_file && !summary_file.empty?
  File.open(summary_file, "a") { |io| io << out }
else
  puts out
end

# --- Annotations ------------------------------------------------------------
# Surface the worst few on the PR diff. Keep it small on purpose.
annotations = []
abc.first(ANNOTATE_N).each do |r|
  annotations << "::warning file=#{r[:file]},line=#{r[:line]}::High ABC size (#{format('%.1f', r[:value])}) in `#{r[:name]}`"
end
by_coupling.first(ANNOTATE_N).each do |path, v|
  next unless v["score"].positive?

  annotations << "::warning file=#{path},line=1::High coupling: fan-in×fan-out = #{v['score']} (#{v['fan_in']}×#{v['fan_out']})"
end
cycles.first(ANNOTATE_N).each do |cycle|
  file = cycle.first
  annotations << "::warning file=#{file},line=1::Circular dependency: #{cycle.map { |p| short(p) }.join(' -> ')}"
end

puts annotations.join("\n") unless annotations.empty?
