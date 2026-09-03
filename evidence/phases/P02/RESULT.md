PHASE: P02
STATUS: DEMONSTRATED

## Claim

P02 extracted a deterministic semantic process graph for every behavior exercised
by the frozen P01 corpus at the frozen Linguist revision (`b88d632053392ec83fdb00cdc2a39ac3cabb301c`
on branch `malbolge-patch-canonical`, parent `d5214e1612c858ba14bf98edeca57e1683276f1d`).
Graph nodes are behavior-oriented, each edge is backed by an observed trace, terminal
outcomes reproduce the P01 oracle evidence, and both trace normalization and graph
derivation are byte-deterministic across fresh invocations.

This is NOT a Ruby AST dump, TracePoint call list, or method-name graph. Every node
is a semantic operation with the frozen upstream source surface it is grounded to.

## Inputs

- Frozen Linguist oracle (same checkout as P00/P01)
- Frozen P01 corpus (`evidence/phases/P01/corpus`, sha256 in P01 hashes)
- Frozen P01 canonical oracle output (`evidence/phases/P01/oracle/run1.normalized.json`,
  sha256 `de259e8322ad1d4c501f270819102ce19d2643333d44d4f1cd2ce07bbb86fb24`)
- P01 parity gate: P02 trace's terminal result must equal P01's observed result.

## Commands

See `commands.txt` for the exact reproduction. Roughly:

1. `py scripts/p01_build_corpus.py --upstream <LINGUIST_COLD>`
2. `docker run ... malbolge-linguist-addgrammar ... p02_trace_oracle.rb` (twice)
3. `py scripts/p02_build_semantic_graph.py --traces run1.normalized.json ...`
4. `py scripts/p02_build_semantic_graph.py --traces run2.normalized.json ...`
5. `py scripts/p02_verify_semantic_graph.py --traces run1 --graph run1 --p01 ...`

## Artifacts and hashes

- `traces/run1.normalized.json` sha256 `2c5f16e5a967977462ebd5aa18172529a0372a5ac3b6d2026d6a5d8d34046fe6`
- `traces/run2.normalized.json` sha256 `2c5f16e5a967977462ebd5aa18172529a0372a5ac3b6d2026d6a5d8d34046fe6`
- `traces/run1.terminal_parity.json` sha256 `7a36061c6298c700d9002692ba4179adf33d5424de8e7ebe5ee246f6e93a17d2`
- `traces/run2.terminal_parity.json` sha256 `7a36061c6298c700d9002692ba4179adf33d5424de8e7ebe5ee246f6e93a17d2`
- `semantic_graph.json` sha256 `a03c6f981ea377ec5b440c95dca6ef1a124c6e488e96a2222a23adb1630044b1`
- `semantic_graph_from_run2.json` sha256 `a03c6f981ea377ec5b440c95dca6ef1a124c6e488e96a2222a23adb1630044b1`
- `source_map.json` sha256 `9b9dc007d76d0df8f93d3ea1b6d5a43419948e6cac6d00b54f0c9423c44db186`
- `data_dependencies.json` sha256 `c5ac33be0fc45d390d8725ed448afc361050a990da1496a73efb1a83fe5234e0`
- `coverage.json` sha256 `27b2fab404e48f1dda5d5fb467342924841c848376bc19056a785310ce2720df`

Harness/script hashes live in `hashes.json`.

## Observed

- Traced 97 cases in total (90 files + 3 repositories + 4 metadata
  lookups). Both fresh invocations of the tracer produce identical
  normalized traces *and* identical graph/summaries.
- 93-grade terminal parity (90 file cases + 3 repo aggregations);
  metadata lookups are sanity-checked against the frozen metadata section
  separately. 0 mismatches vs the frozen P01 oracle.
- Semantic graph: **34 semantic operations**, **51 observed edges** backed
  by traces, no phantom transitions.
- Coverage is complete: every P01 section (A–I) has `cases_total`,
  `cases_traced`, `cases_with_terminal_result_match`, and observed
  semantic operations. Total cases traced = 97 (100% of the P01 corpus).

The semantic operations discovered (from the frozen upstream API surface):

```
detect.started / detect.terminal
strategy.modeline          strategy.modeline.result
strategy.filename          strategy.filename.result
strategy.shebang           strategy.shebang.result
strategy.extension         strategy.extension.result
strategy.xml               strategy.xml.result
strategy.manpage           strategy.manpage.result
heuristics.call            heuristics.call.result
classifier.call            classifier.call.result
flag.binary_check
flag.vendored
flag.generated
flag.documentation
repo.include_in_language_stats
repo.languages_aggregate
repo.breakdown_by_file
metadata.find_by_alias(.result)         metadata.find_by_filename(.result)
metadata.find_by_extension(.result)     metadata.find_by_interpreter(.result)
metadata.language_lookup
```

(That is 34 graph nodes counting the wrapped `.result` companions.)

## Not observed

- No Ruby AST / call-graph leakage: the graph vocabulary is semantic, not method names.
- No host-semantic decision anywhere: all language/type/flags came from the frozen
  upstream API. The tracer only *records calls*; it doesn't fabricate results.
- No path leaks or host-specific data in normalized outputs (paths are fixture-relative).
- No nondeterminism: run1 and run2 produced byte-identical traces, parity docs and
  semantic graphs.

## Confounds

- I did **not** cover every conceivable Linguist branch — only the ones the
  frozen P01 corpus actually exercised. That is exactly what the P01 corpus froze.
  Out-of-corpus behavior is explicitly out of scope for this phase.
- `.metadata.language_lookup` cases are a classicity record, not full detect;
  they only show the `Language[name]` contraction from the frozen index.

## Gate

```
P02_FROZEN_ORACLE_REVISION_MATCH        = TRUE
P02_INSTRUMENTATION_NON_INTERFERENCE    = TRUE  (taps only record; they never mutate, and the parity run proves terminals unchanged)
P02_P01_FROZEN_CASES_TRACED             = TRUE  (97/97 = 100%)
P02_TERMINAL_RESULTS_MATCH_P01          = TRUE  (93/93 parity + metadata coverage)
P02_NORMALIZED_TRACE_DETERMINISTIC      = TRUE  (run1.normalized == run2.normalized byte-equal)
P02_GRAPH_DETERMINISTIC                 = TRUE  (graph_from_run1 == graph_from_run2 byte-equal)
P02_GRAPH_MECHANICALLY_DERIVED          = TRUE  (semantic_graph.json produced by scripts/p02_build_semantic_graph.py, not hand-written)
P02_GRAPH_NOT_RUBY_AST_OR_CALLGRAPH     = TRUE  (operations are semantic/stateful verbs)
P02_NODE_SOURCE_PROVENANCE_COMPLETE      = TRUE  (source_map.json covers every node ID)
P02_DATA_DEPENDENCIES_HASHED            = TRUE  (data_dependencies.json carries sha256)
P02_EDGE_TRACE_BACKING_COMPLETE         = TRUE  (every edge appears in at least one trace)
P02_FREQUENCY_VERIFIED                  = TRUE  (node frequency counted from trace events)
P02_PRIVACY_NORMALIZATION_PASS          = TRUE  (relative fixture names only, no absolute paths in traces)
```

## Next action

P02 complete. Stop. Do not start P03 without a new NEXT.md packet.
