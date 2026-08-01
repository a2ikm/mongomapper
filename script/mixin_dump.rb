# frozen_string_literal: true

# Boots MongoMapper and reflects on the *composed* Document / EmbeddedDocument
# classes, dumping mixin facts as JSON on STDOUT.
#
# Why a running process: `include` / `extend` are executed at runtime, and the
# owning class of a plugin module is not lexically present in its source, so a
# pure static pass cannot know which modules end up composed onto the same
# object. After boot, reflection reads that composition as an accomplished
# fact. build_summary.rb joins this with the per-module instance-variable
# writes collected statically (deps.json) to spot mixin overuse and shared
# mutable state.
#
# Scope: only structure established at load time is captured. Mixins applied
# dynamically while an app runs are out of scope (rare, and deliberately
# excluded). No MongoDB connection is made — composition is triggered by
# `include`, and connecting is lazy.

require "json"
require "mongo_mapper"

FIRST_PARTY = "MongoMapper"

def first_party?(mod)
  mod.name&.start_with?(FIRST_PARTY)
end

# Methods a module defines itself (public + private), regardless of whether a
# later mixin overrides them — we want the surface each mixin contributes.
def own_method_count(mod)
  (mod.instance_methods(false) | mod.private_instance_methods(false)).size
end

def dump(klass)
  instance_mixins = klass.ancestors.select { |m| m != klass && first_party?(m) }
  # Class methods come from modules extended onto the class; ActiveSupport::
  # Concern puts each plugin's ClassMethods into the singleton ancestor chain.
  class_mixins = klass.singleton_class.ancestors.select { |m| first_party?(m) }

  {
    "instance_mixins" => instance_mixins.map(&:to_s),
    "class_mixins" => class_mixins.map(&:to_s),
    "instance_methods_by_module" => instance_mixins.to_h { |m| [m.to_s, own_method_count(m)] },
    "class_methods_by_module" => class_mixins.to_h { |m| [m.to_s, own_method_count(m)] },
  }
end

document = Class.new { include MongoMapper::Document }
embedded = Class.new { include MongoMapper::EmbeddedDocument }

puts JSON.pretty_generate(
  "objects" => {
    "Document" => dump(document),
    "EmbeddedDocument" => dump(embedded),
  }
)
