# frozen_string_literal: true
# P02 trace harness. Runs the frozen Linguist oracle over the frozen P01
# corpus while collecting per-case semantic traces of the public calls that
# actually executed. Instrumentation is prepend-only wrappers that record the
# public call surface — they never alter return values.
#
# Usage:
#   ruby -I/work/patched/lib \
#     scripts/p02_trace_oracle.rb \
#       --corpus <corpus_root> --out <normalized_traces.json> \
#       --raw <raw_traces.json> --p01-results <p01_normalized.json>

require "json"
require "optparse"
require "openssl"
require "tempfile"
require "fileutils"

options = {}
OptionParser.new do |o|
  o.on("--patch-lib PATH") { |v| options[:patch_lib] = v }
  o.on("--corpus PATH")    { |v| options[:corpus] = v }
  o.on("--out PATH")       { |v| options[:out] = v }
  o.on("--raw PATH")       { |v| options[:raw] = v }
  o.on("--p01 PATH")       { |v| options[:p01] = v }
end.parse! ARGV

$LOAD_PATH.unshift(options[:patch_lib])

require "linguist"
require "linguist/instrumenter"
require "rugged"

P01 = JSON.parse(File.read(File.expand_path(options[:p01])), symbolize_names: false)

CORPUS = File.expand_path(options[:corpus])

# -----------------------------------------------------------------------------
#.Trace event collector — per case, ordered, deterministic, privacy-safe
# -----------------------------------------------------------------------------

module P02
  # A single in-memory event list for the currently traced case.
  # Each event: op, inputs, reads, writes, data, outcome.
  class Tap
    attr_reader :seq, :events
    def initialize(case_id)
      @case_id = case_id
      @seq = 0
      @events = []
    end

    def record(operation, inputs:, state_read:, state_write:, data:, outcome:)
      @seq += 1
      @events << {
        "seq" => @seq,
        "operation" => operation,
        "inputs" => inputs,
        "state_read" => state_read,
        "state_write" => state_write,
        "data_dependencies" => data,
        "outcome" => outcome,
      }
    end
  end

  # Current-case holder (plain Ruby, no ActiveSupport).
  module Current
    @tap = nil

    def self.tap
      @tap
    end

    def self.tap=(value)
      @tap = value
    end
  end

  def self.tap!(case_id)
    Current.tap = Tap.new(case_id)
  end

  def self.current_tap
    Current.tap
  end

  # ---------------------------------------------------------------------------
  # Prepend-based taps. Each wrapper:
  #   1. captures inputs (canonicalized),
  #   2. calls super (the real upstream method),
  #   3. records the event with the upstream-computed result.
  # It never changes the return value.
  # ---------------------------------------------------------------------------

  module DetectTap
    def detect(blob, allow_empty: false)
      tap = P02.current_tap
      tap&.record(
        "detect.started",
        inputs: {
          "name" => blob.name, "size" => blob.size,
        },
        state_read: [], state_write: [],
        data: [],
        outcome: nil,
      )
      result = super
      tap&.record(
        "detect.terminal",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: [],
        outcome: { "language" => result&.name },
      )
      result
    end
  end

  module ModelineTap
    def call(blob, candidates_in)
      tap = P02.current_tap
      tap&.record(
        "strategy.modeline",
        inputs: {
          "name" => blob.name,
          "extname" => blob.extname,
          "candidates_in" => candidates_in.map(&:name).sort,
        },
        state_read: [], state_write: [],
        data: ["lib/linguist/strategy/modeline.rb"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "strategy.modeline.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/strategy/modeline.rb"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module FilenameTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "strategy.filename",
        inputs: { "name" => blob.name, "candidates_in" => candidates.map(&:name).sort },
        state_read: ["Language.filename_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "strategy.filename.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module ShebangTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "strategy.shebang",
        inputs: { "name" => blob.name, "candidates_in" => candidates.map(&:name).sort },
        state_read: ["Language.interpreter_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "strategy.shebang.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module ExtensionTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "strategy.extension",
        inputs: { "name" => blob.name, "extname" => blob.extname, "candidates_in" => candidates.map(&:name).sort },
        state_read: ["Language.extension_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml", "lib/linguist/generic.yml"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "strategy.extension.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module XMLTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "strategy.xml",
        inputs: { "name" => blob.name, "candidates_in" => candidates.map(&:name).sort },
        state_read: [],
        state_write: [],
        data: ["lib/linguist/strategy/xml.rb"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "strategy.xml.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/strategy/xml.rb"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module ManpageTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "strategy.manpage",
        inputs: { "name" => blob.name, "candidates_in" => candidates.map(&:name).sort },
        state_read: [],
        state_write: [],
        data: ["lib/linguist/strategy/manpage.rb"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "strategy.manpage.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/strategy/manpage.rb"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module HeuristicsTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "heuristics.call",
        inputs: { "name" => blob.name, "extname" => blob.extname, "candidates_in" => candidates.map(&:name).sort },
        state_read: ["Language.extension_index"],
        state_write: [],
        data: ["lib/linguist/heuristics.yml", "lib/linguist/heuristics.rb"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "heuristics.call.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/heuristics.yml"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  module ClassifierTap
    def call(blob, candidates)
      tap = P02.current_tap
      tap&.record(
        "classifier.call",
        inputs: { "name" => blob.name, "candidates_in" => candidates.map(&:name).sort },
        state_read: ["Classifier.Samples.cache"],
        state_write: [],
        data: ["lib/linguist/samples_data.rb"],
        outcome: nil,
      )
      out = super
      tap&.record(
        "classifier.call.result",
        inputs: { "name" => blob.name },
        state_read: [], state_write: [],
        data: ["lib/linguist/samples_data.rb"],
        outcome: { "candidates" => out.map(&:name).sort },
      )
      out
    end
  end

  # Blob flag taps (vendored/generated/documentation include gating)
  module BlobFlagTap
    def vendored?
      v = super
      P02.current_tap&.record(
        "flag.vendored",
        inputs: { "name" => name },
        state_read: [],
        state_write: [],
        data: ["lib/linguist/vendor.yml"],
        outcome: { "vendored" => v },
      )
      v
    end

    def generated?
      v = super
      P02.current_tap&.record(
        "flag.generated",
        inputs: { "name" => name, "extname" => File.extname(name) },
        state_read: [],
        state_write: [],
        data: ["lib/linguist/generated.rb"],
        outcome: { "generated" => v },
      )
      v
    end

    def documentation?
      v = super
      P02.current_tap&.record(
        "flag.documentation",
        inputs: { "name" => name },
        state_read: [],
        state_write: [],
        data: ["lib/linguist/documentation.yml"],
        outcome: { "documentation" => v },
      )
      v
    end

    def binary?
      v = super
      P02.current_tap&.record(
        "flag.binary_check",
        inputs: { "name" => name, "size" => size },
        state_read: [],
        state_write: [],
        data: [],
        outcome: { "binary" => v },
      )
      v
    end

    def include_in_language_stats?
      v = super
      P02.current_tap&.record(
        "repo.include_in_language_stats",
        inputs: { "name" => name },
        state_read: [],
        state_write: [],
        data: [],
        outcome: { "include" => v },
      )
      v
    end
  end

  # Language metadata lookups
  module LanguageMetaTap
    def find_by_filename(name)
      P02.current_tap&.record(
        "metadata.find_by_filename",
        inputs: { "name" => name },
        state_read: ["Language.filename_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: nil,
      )
      super.tap do |result|
        P02.current_tap&.record(
          "metadata.find_by_filename.result",
          inputs: { "name" => name },
          state_read: [], state_write: [],
          data: [],
          outcome: { "languages" => result.map(&:name) },
        )
      end
    end

    def find_by_extension(ext)
      P02.current_tap&.record(
        "metadata.find_by_extension",
        inputs: { "extname" => ext },
        state_read: ["Language.extension_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: nil,
      )
      super.tap do |result|
        P02.current_tap&.record(
          "metadata.find_by_extension.result",
          inputs: { "extname" => ext },
          state_read: [], state_write: [],
          data: [],
          outcome: { "languages" => result.map(&:name) },
        )
      end
    end

    def find_by_interpreter(name)
      P02.current_tap&.record(
        "metadata.find_by_interpreter",
        inputs: { "interpreter" => name },
        state_read: ["Language.interpreter_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: nil,
      )
      super.tap do |result|
        P02.current_tap&.record(
          "metadata.find_by_interpreter.result",
          inputs: { "interpreter" => name },
          state_read: [], state_write: [],
          data: [],
          outcome: { "languages" => result.map(&:name) },
        )
      end
    end

    def find_by_alias(name)
      P02.current_tap&.record(
        "metadata.find_by_alias",
        inputs: { "alias" => name },
        state_read: ["Language.alias_index"],
        state_write: [],
        data: ["lib/linguist/languages.yml"],
        outcome: nil,
      )
      super.tap do |result|
        P02.current_tap&.record(
          "metadata.find_by_alias.result",
          inputs: { "alias" => name },
          state_read: [], state_write: [],
          data: [],
          outcome: { "language" => result&.name },
        )
      end
    end
  end

  # Repository aggregation taps
  module RepoTap
    def languages
      r = super
      P02.current_tap&.record(
        "repo.languages_aggregate",
        inputs: {},
        state_read: ["Repository.cache"],
        state_write: [],
        data: [],
        outcome: { "languages" => r.sort.to_h },
      )
      r
    end

    def breakdown_by_file
      b = super
      P02.current_tap&.record(
        "repo.breakdown_by_file",
        inputs: {},
        state_read: ["Repository.cache"],
        state_write: [],
        data: [],
        outcome: { "by_language_counts" => b.map { |k, v| [k, v.length] }.sort.to_h },
      )
      b
    end
  end

  def self.install!(klass)
    klass.singleton_class.prepend(ModelineTap) if klass == Linguist::Strategy::Modeline
    klass.singleton_class.prepend(FilenameTap) if klass == Linguist::Strategy::Filename
    klass.singleton_class.prepend(ShebangTap) if klass == Linguist::Shebang
    klass.singleton_class.prepend(ExtensionTap) if klass == Linguist::Strategy::Extension
    klass.singleton_class.prepend(XMLTap) if klass == Linguist::Strategy::XML
    klass.singleton_class.prepend(ManpageTap) if klass == Linguist::Strategy::Manpage
    klass.singleton_class.prepend(HeuristicsTap) if klass == Linguist::Heuristics
    klass.singleton_class.prepend(ClassifierTap) if klass == Linguist::Classifier
  end
end

# Install taps
Linguist.singleton_class.prepend(P02::DetectTap)
P02.install!(Linguist::Strategy::Modeline)
P02.install!(Linguist::Strategy::Filename)
P02.install!(Linguist::Shebang)
P02.install!(Linguist::Strategy::Extension)
P02.install!(Linguist::Strategy::XML)
P02.install!(Linguist::Strategy::Manpage)
P02.install!(Linguist::Heuristics)
P02.install!(Linguist::Classifier)
Linguist::Blob.prepend(P02::BlobFlagTap)
Linguist::FileBlob.prepend(P02::BlobFlagTap)
Linguist::LazyBlob.prepend(P02::BlobFlagTap)
Linguist::Language.singleton_class.prepend(P02::LanguageMetaTap)
Linguist::Repository.prepend(P02::RepoTap)

def sha256_bytes(s) = OpenSSL::Digest::SHA256.hexdigest(s)

manifest = JSON.parse(File.read(File.join(CORPUS, "manifest.json")), symbolize_names: false)

# -----------------------------------------------------------------------------
# Per-case tracing
# -----------------------------------------------------------------------------

# Map P01 case IDs to expected terminal language for parity check at the end.
p01_terminal = {}
P01["files"].each { |id, obs| p01_terminal[id] = obs["language"] }

# Repo section stored differently in P01 harness (not in files). Compare separately.
p01_repos = P01["repos"]

def p01_case_id_from(rel)
  rel.sub(%r{\Acorpus/}, "").tr("/", "_").gsub(%r{\Acorpus/files/}, "").gsub(/\Afiles\//, "").gsub("/", "__")
end

traces = []
files_pairwise = []

manifest["files"].each do |entry|
  rel = entry["relative_path"]
  path = File.join(CORPUS, rel.sub(%r{\Acorpus/}, ""))
  case_id = entry["id"]

  P02.tap!(case_id)
  blob = Linguist::FileBlob.new(path)
  language = blob.language rescue nil
  # Trigger flags explicitly so they appear in trace (same sequence each run)
  _ = blob.vendored?; _ = blob.generated?; _ = blob.documentation?
  trace = P02.current_tap.events

  normalized_events = trace.map do |ev|
    {
      "seq" => ev["seq"],
      "operation" => ev["operation"],
      "inputs" => Hash[ev["inputs"].sort],
      "state_read" => ev["state_read"].sort,
      "state_write" => ev["state_write"].sort,
      "data_dependencies" => ev["data_dependencies"].sort,
      "outcome" => ev["outcome"].is_a?(Hash) ? Hash[ev["outcome"].sort] : ev["outcome"],
    }
  end

  terminal_lang = language&.name
  traces << {
    "case_id" => case_id,
    "kind" => "file",
    "relative_path" => rel,
    "fixture_sha256" => entry["sha256"],
    "event_count" => normalized_events.length,
    "events" => normalized_events,
    "terminal_language" => terminal_lang,
  }
  files_pairwise << [case_id, terminal_lang]
end

# C metadata lookups (4 languages)
manifest["metadata_languages"].each do |lang_name|
  case_id = "metadata__#{lang_name}"
  lang = Linguist::Language[lang_name]
  P02.tap!(case_id)
  P02.current_tap.record(
    "metadata.language_lookup",
    inputs: { "language" => lang_name },
    state_read: ["Language.name_index"],
    state_write: [],
    data: ["lib/linguist/languages.yml"],
    outcome: {
      "found" => !lang.nil?,
      "name" => lang&.name,
      "group" => lang&.group,
      "type" => lang&.type&.to_s,
      "color" => lang&.color,
      "aliases" => lang&.aliases,
      "extensions" => lang&.extensions,
      "filenames" => lang&.filenames,
      "interpreters" => lang&.interpreters,
      "tm_scope" => lang&.tm_scope,
      "language_id" => lang&.language_id,
      "fs_name" => lang&.fs_name,
      "ace_mode" => lang&.ace_mode,
    },
  )
  mapping = P02.current_tap.events
  traces << {
    "case_id" => case_id,
    "kind" => "metadata",
    "event_count" => mapping.length,
    "events" => mapping,
    "terminal_language" => lang&.name,
  }
end

# H repository aggregation
def build_repo(name, fixtures_root, tmp_root)
  rdir = File.join(tmp_root, name)
  FileUtils.mkdir_p(rdir)
  src_root = File.join(fixtures_root, name)
  Dir.glob(File.join(src_root, "**", "*"), File::FNM_DOTMATCH).each do |src|
    next if File.directory?(src)
    rel = src.sub("#{src_root}/", "")
    dest = File.join(rdir, rel)
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(src, dest)
  end
  git_repo = nil
  Dir.chdir(rdir) do
    system("git init -q >NUL 2>&1 || git init -q")
    system("git", "config", "user.email", "bolgang+p02@example.invalid")
    system("git", "config", "user.name", "bolgang-p02")
    ENV["GIT_AUTHOR_DATE"] = "2000-01-01T00:00:00Z"
    ENV["GIT_COMMITTER_DATE"] = "2000-01-01T00:00:00Z"
    system("git add -A")
    system("git", "commit", "-q", "-m", "P02 repo fixture")
    git_repo = Rugged::Repository.new(rdir)
  end
  git_repo
end

manifest["repos"].each do |entry|
  name = entry["id"]
  Dir.mktmpdir("p02_repo_") do |tmp_root|
    P02.tap!("repo__#{name}")
    git_repo = build_repo(name, File.join(CORPUS, "repos"), tmp_root)
    head_oid = git_repo.rev_parse_oid("HEAD")
    repo = Linguist::Repository.new(git_repo, head_oid)
    languages = repo.languages rescue {}
    breakdown = repo.breakdown_by_file rescue {}
    events = P02.current_tap.events
    traces << {
      "case_id" => "repo__#{name}",
      "kind" => "repository",
      "relative_path" => "corpus/repos/#{name}",
      "event_count" => events.length,
      "events" => events.map do |ev|
        {
          "seq" => ev["seq"],
          "operation" => ev["operation"],
          "inputs" => Hash[ev["inputs"].sort],
          "state_read" => ev["state_read"].sort,
          "state_write" => ev["state_write"].sort,
          "data_dependencies" => ev["data_dependencies"].sort,
          "outcome" => ev["outcome"].is_a?(Hash) ? Hash[ev["outcome"].sort] : ev["outcome"],
        }
      end,
      "terminal_languages_by_bytes" => languages.sort.to_h,
      "languages" => languages.keys.sort,
      "aggregate_bytes" => languages.values.sum,
    }
  end
end

# -----------------------------------------------------------------------------
# Terminal parity against P01 frozen oracle
# -----------------------------------------------------------------------------

parity = []
totals = { "match" => 0, "mismatch" => 0 }
files_pairwise.each do |case_id, observed_lang|
  expected = p01_terminal[case_id]
  match = observed_lang == expected
  totals[match ? "match" : "mismatch"] += 1
  parity << {
    "case_id" => case_id,
    "expected_from_p01" => expected,
    "observed_in_p02" => observed_lang,
    "equal" => match,
  }
end

# Parity for repos: compare languages bytes map against P01 repos section.
pfx_repos = {}
manifest["repos"].each do |entry|
  name = entry["id"]
  this_run = traces.select { |t| t["case_id"] == "repo__#{name}" }[0]
  p01_repo = p01_repos[name] || {}
  this_langs = this_run["terminal_languages_by_bytes"]
  p01_langs = p01_repo["languages_bytes"]
  # P01 emitted per-language file counts; here compare total byte aggregation.
  p01_total = p01_langs.values rescue []
  p01_total = p01_langs.values.reduce(:+) rescue nil
  this_total = this_langs.values.reduce(:+) rescue 0
  match = this_total == p01_total
  totals[match ? "match" : "mismatch"] += 1
  parity << {
    "case_id" => "repo__#{name}",
    "expected_from_p01_total_bytes" => p01_total,
    "observed_in_p02_total_bytes" => this_total,
    "equal" => match,
  }
end

traces_doc = {
  "schema" => "p02-trace/1",
  "p01_reference" => "evidence/phases/P01/oracle/run1.normalized.json",
  "traces" => traces.sort_by { |t| t["case_id"] },
}

parity_doc = {
  "schema" => "p02-terminal-parity/1",
  "totals" => totals,
  "cases" => parity.sort_by { |p| p["case_id"] },
}

File.open(options[:out], "wb") { |f| f.write(JSON.generate(traces_doc)); f.write("\n") }
File.open(options[:raw], "wb") { |f| f.write(JSON.pretty_generate(traces_doc)); f.write("\n") }

parity_path = options[:out].sub(/normalized\.json$/, "terminal_parity.json")
File.open(parity_path, "wb") { |f| f.write(JSON.generate(parity_doc)); f.write("\n") }

puts "OK traced #{traces.length} cases. parity match=#{totals['match']} mismatch=#{totals['mismatch']}"