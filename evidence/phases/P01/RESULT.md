PHASE: P01
STATUS: DEMONSTRATED

## Claim

The exact frozen Linguist revision produced a deterministic canonical output
for the frozen P01 observable corpus. No claim is made about Malbolge parity.

## Inputs

- Frozen working oracle (per P00):
  - repo: github-linguist/linguist
  - pristine origin/main: `d5214e1612c858ba14bf98edeca57e1683276f1d`
  - working oracle HEAD: `b88d632053392ec83fdb00cdc2a39ac3cabb301c`
    (branch `malbolge-patch-canonical`, parent = pristine upstream commit;
     verified `git status --porcelain` clean)
  - on-disk checkout path: `<REDACTED>/malbolge-linguist/upstream`
- Corpus: `evidence/phases/P01/corpus/` (manifest + files + repos + tier)
- Harness: `scripts/p01_probe.rb` (and its input builder
  `scripts/p01_build_corpus.py`)
- Project HEAD at start of phase: `867825a5055e123cca9cca0cb56e4329fccdd7a6`
  (P00: freeze oracle and Classic runtime provenance)

## Commands

See `commands.txt`. All oracle work runs inside the pinned container
`malbolge-linguist-addgrammar:latest` mounting the frozen upstream and the
frozen bundle volume `malbolge-canonical-bundle`. Host paths are present only
in `commands.txt`/`raw_stdout.txt` and are normalization targets.

## Artifacts and hashes

- `corpus/manifest.json` sha256: `04998a2482f5fc6ab9488669b873f2f614d116191a76ef87f1ca1977e669834a`
- `oracle/run1.normalized.json` sha256: `de259e8322ad1d4c501f270819102ce19d2643333d44d4f1cd2ce07bbb86fb24`
- `oracle/run2.normalized.json` sha256: `de259e8322ad1d4c501f270819102ce19d2643333d44d4f1cd2ce07bbb86fb24`
- IDENTICAL — fresh invocations produced byte-identical normalized output.
- `oracle/run1.raw.json` sha256: `7601703e8fd45a29dcb9e647f24d010d67b2289c51f5f180e77c38c49ef567f4`
- `oracle/run2.raw.json` sha256: `7601703e8fd45a29dcb9e647f24d010d67b2289c51f5f180e77c38c49ef567f4`
- IDENTICAL.

Every corpus fixture is SHA256-hashed in `corpus/manifest.json` (each `sha256`
field). For the tier, each copied file carries the same `sha256` pointer. The
manifest SHA256 is also pinned in `hashes.json`.

## Observed

The frozen oracle produced these observable outcomes (each from the live
Linguist API, not from an expected-answer table):

- **Section A (extension-driven)**: `a_ext__hello_py.py` → Python/Extension; `.rb` → Ruby/Extension; `.js` → JavaScript/Extension; `.c` → C/Extension; `.go` → Go/Extension; `.rs` → Rust/Heuristics; `truth_machine.malbolge` → Malbolge/Extension (7/7 language identified).
- **Section B (filename)**: Gemfile → Ruby/Filename; Dockerfile → Dockerfile/Filename; Makefile → Makefile/Filename; CMakeLists.txt → CMake/Filename (4/4).
- **Section C (metadata)**: Malbolge (extensions=[".malbolge"], type=programming, aliases=["malbolge"], language_id=1006177966), Python, Ruby, JavaScript — all found=true, all fields populated.
- **Section D (shebang)**: `py_script` → Python/Shebang; `sh_script.sh` → Shell/Shebang; `pl_script` → Perl/Classifier (the perl shebang matches *both* Perl and Pod languages, so the shebang strategy returns two candidates and falls through to the heuristic chain). The interpreter resolution was verified by direct API call (recorded in raw output).
- **Section E (modeline)**: `emacs_py.txt` → Python/Modeline; `vim_js.txt` → JavaScript/Modeline; `emacs_ruby.txt` → Ruby/Modeline (3/3).
- **Section F (ambiguous/heuristics)**: `.pl` group: Perl/Heuristics AND Prolog/Heuristics (two contrasting outcomes from same extension). `.h` group: Objective-C/Heuristics AND C++/Heuristics. 4/4 cases, 2 distinct groups.
- **Section G (flags)**:
  - vendor_positive (node_modules/jquery.js): vendored=TRUE, generated=TRUE
  - vendor_negative (index.js): vendored=FALSE, generated=FALSE
  - generated_positive (Cargo.lock): generated=TRUE, vendored=FALSE
  - generated_negative (main.rs): generated=FALSE
  - documentation_positive (README.md): documentation=TRUE
  - documentation_negative (app.py): documentation=FALSE
  (Each flag has one positive and one negative case.)
- **Section H (repository aggregation)**:
  - `repo_micro`: languages_bytes={"Python":15}, total_bytes=15, breakdown=1 file → Python.
  - `repo_mixed`: languages_bytes={"JavaScript":19,"Python":12,"Ruby":10}, total_bytes=41.
  - `repo_filtered`: languages_bytes={"Python":12}, total_bytes=12 (vendored js + generated lockfile + README correctly excluded; only main.py counted).
- **Section I (large tier)**: 63 files sampled from `upstream/samples/`,
  ≤ 16 KiB each, one per language directory alphabetically. All observed with
  a language identification. Total file cases = 90.

The full per-file observations are in `oracle/run1.normalized.json`.

## Not observed

- ORACLE_REVISION_MISMATCH: working tree clean, HEAD/parent exactly as frozen.
- ORACLE_NONDETERMINISM: TWO fresh invocations produced IDENTICAL normalized
  and IDENTICAL raw output (hash match above).
- HOST_SEMANTIC_DECISION: the harness is a thin RPC probe; all language, type,
  alias, strategy, vendored/generated/documentation results came from Linguist
  API calls. Nothing was short-circuited by the harness.
- Optional Classic interpreter #2 requirement for P01: not applicable at this
  phase gate (P01 is oracle-only).

## Confounds

- `d_shebang/pl_script` falls through from Shebang to Heuristics→Classifier
  because the `perl` interpreter name matches both the Perl and Pod languages
  (verified: `find_by_interpreter("perl") = ["Perl", "Pod"]`). The observed
  outcome (Perl) is real upstream behavior; the shebang strategy DID run, it
  simply produced two candidates. This is not evidence of a defective shebang
  path; it is how the frozen revision behaves for that name.
- The frozen oracle produces `linguist-9.x` style output via API; we do not
  include the Linguist `VERSION` string in the normalized output because the
  frozen revision's own `lib/linguist/version.rb` is a perfect source and
  normalization does not alter its semantics.

## Gate

```
LINGUIST_ORACLE_REVISION_FROZEN = TRUE(verified)
CLASSIC_INTERPRETER_1_FROZEN    = TRUE(APPLIES: not required by P01)
CLASSIC_KNOWN_VECTOR_PASS       = NOT_APPLICABLE(P01 is oracle-only)
NORMALIZATION_FROZEN            = TRUE
HOST_BOUNDARY_FROZEN            = TRUE
ORACLE_REVISION_MATCH           = TRUE
ORACLE_DETERMINISTIC            = TRUE
SECTIONS_A-I_COVERAGE           = PASS (all criteria met)
```

NEXT_GATE: P02_SEMANTIC_GRAPH

## Next action

If `P02` is authorized via a future `_NEXT_PHASE/NEXT.md`, extract the semantic
process graph from the now-frozen oracle behaviors. Otherwise STOP.