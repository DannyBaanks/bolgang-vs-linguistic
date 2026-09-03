# frozen_string_literal: true
# P01 oracle probe. Reads corpus/manifest.json and asks the frozen Linguist
# implementation what it returns for each frozen input. The harness never
# carries expected answers: it reports raw upstream observations only.
#
# Usage:
#   ruby p01_probe.rb --patch-lib /work/patched/lib \
#       --corpus <corpus_root> --out <normalized.json> --raw <raw.json>

require "json"
require "optparse"
require "openssl"
require "tempfile"
require "fileutils"

options = {}
OptionParser.new do |opts|
  opts.on("--patch-lib PATH") { |v| options[:patch_lib] = v }
  opts.on("--corpus PATH") { |v| options[:corpus] = v }
  opts.on("--out PATH") { |v| options[:out] = v }
  opts.on("--raw PATH") { |v| options[:raw] = v }
end.parse! ARGV

$LOAD_PATH.unshift(options[:patch_lib])

require "linguist"
require "linguist/instrumenter"
require "rugged"

corpus = File.expand_path(options[:corpus])
manifest = JSON.parse(File.read(File.join(corpus, "manifest.json")), symbolize_names: false)

# Manifest relative paths are prefixed with corpus/. Resolve them against the
# corpus root without duplicating that prefix.
def resolve_in_corpus(corpus, rel)
  rel = rel.sub(%r{\Acorpus/}, "")
  File.join(corpus, rel)
end

def sha256_file(path)
  OpenSSL::Digest.file(path, "SHA256").hexdigest
end

Linguist.instrumenter = Linguist::BasicInstrumenter.new

def probe_blob(blob)
  # Per-blob instrumenter so strategy attribution is exact and
  # basename collisions across fixtures cannot leak.
  ins = Linguist::BasicInstrumenter.new
  Linguist.instrumenter = ins
  language = blob.language&.name
  info = ins.detected_info[blob.name]
  [language, info && info[:strategy]]
end

results = {}
raw = {}

# --------------------------------------------------------------------------
# Section A & co: per-file classifications through the frozen oracle
# --------------------------------------------------------------------------

manifest["files"].each do |entry|
  rel = entry["relative_path"]
  path = resolve_in_corpus(corpus, rel)
  blob = Linguist::FileBlob.new(path)

  language = nil
  strategy = nil
  begin
    language, strategy = probe_blob(blob)
  rescue => e
    language = nil
    strategy = "error:#{e.class}"
  end

  # NOTE: flags/bytes come from Linguist APIs only. Nothing is precomputed or
  # expected here except re-recording the size/sha256 of frozen inputs.
  flags = {
    "vendored"         => blob.vendored?,
    "generated"        => blob.generated?,
    "documentation"    => blob.documentation?,
    "binary"           => blob.binary?,
    "text"             => blob.text?,
  }

  observe = {
    "language"  => language,
    "strategy"  => strategy,
    "extname"   => blob.extname,
    "mime_type" => blob.mime_type&.to_s,
    "size"      => blob.size,
    "loc"       => blob.loc,
    "sloc"      => blob.sloc,
    "flags"     => flags,
  }
  results[entry["id"]] = observe

  raw[entry["id"]] = {
    "platform_path" => path,
    "observed"      => observe,
  }
end

# --------------------------------------------------------------------------
# Section C: language metadata via Linguist's own lookup surface
# --------------------------------------------------------------------------

metadata = {}
manifest["metadata_languages"].each do |name|
  lang = Linguist::Language[name]
  if lang.nil?
    metadata[name] = { "found" => false }
    next
  end
  metadata[lang.name] = {
    "found"        => true,
    "fs_name"      => lang.fs_name,
    "group"        => lang.group,
    "type"         => lang.type.to_s,
    "color"        => lang.color,
    "aliases"      => lang.aliases,
    "extensions"   => lang.extensions,
    "filenames"    => lang.filenames,
    "interpreters" => lang.interpreters,
    "tm_scope"     => lang.tm_scope,
    "ace_mode"     => lang.ace_mode,
    "language_id"  => lang.language_id,
  }
end

# --------------------------------------------------------------------------
# Section H: repository aggregation via Linguist::Repository
# --------------------------------------------------------------------------
# Git commit shas are made deterministic with fixed author/timestamp env so
# repo->languages is reproducible byte-for-byte across runs.

def build_repo(name, fixtures_root, tmp_root)
  repo_dir = File.join(tmp_root, name)
  FileUtils.mkdir_p(repo_dir)
  source_root = File.join(fixtures_root, name)
  Dir.glob(File.join(source_root, "**", "*"), File::FNM_DOTMATCH).each do |src|
    next if File.directory?(src)
    rel = src.sub("#{source_root}/", "")
    dest = File.join(repo_dir, rel)
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(src, dest)
  end
  repo = nil
  Dir.chdir(repo_dir) do
    system("git init -q")
    system("git", "config", "user.email", "bolgang+p01@example.invalid")
    system("git", "config", "user.name", "bolgang-p01")
    ENV["GIT_AUTHOR_DATE"] = "2000-01-01T00:00:00Z"
    ENV["GIT_COMMITTER_DATE"] = "2000-01-01T00:00:00Z"
    system("git add -A")
    system("git", "commit", "-q", "-m", "P01 repo fixture")
  end
  repo_dir
end

repos = {}
manifest["repos"].each do |cnt|
  name = cnt["id"]
  Dir.mktmpdir("p01_repo_") do |tmp_root|
    repo_dir = build_repo(name, File.join(corpus, "repos"), tmp_root)
    git_repo = Rugged::Repository.new(repo_dir)
    head_oid = git_repo.rev_parse_oid("HEAD")
    repo = Linguist::Repository.new(git_repo, head_oid)
    languages = repo.languages # { "Lang" => size }
    files_by_lang = repo.breakdown_by_file # { "Lang" => [filenames] }
    repos[name] = {
      "languages_bytes" => languages.map { |lang, size| [lang, size] }.sort_by { |l, _| l }.to_h,
      "breakdown_file_count" => files_by_lang.map { |lang, fs| [lang, fs.length] }.sort_by { |l, _| l }.to_h,
      "total_bytes" => repo.size,
    }
  end
end

normalized = {
  "schema"  => "p01-oracle-run/1",
  "harness" => "scripts/p01_probe.rb",
  "files"   => results.sort.to_h,
  "metadata"=> metadata.sort.to_h,
  "repos"   => repos.sort.to_h,
}

File.open(options[:out], "wb") do |f|
  f.write(JSON.generate(normalized))
  f.write("\n")
end

File.open(options[:raw], "wb") do |f|
  f.write(JSON.pretty_generate(raw))
  f.write("\n")
end

puts "OK probe ran. #{results.length} file cases, #{metadata.length} metadata, #{repos.length} repos."