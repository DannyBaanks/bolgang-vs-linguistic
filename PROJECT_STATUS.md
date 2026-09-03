# Project Status

```text
CURRENT_PHASE                = P03

P00_PROVENANCE_FROZEN        = DEMONSTRATED
P01_ORACLE_CORPUS            = DEMONSTRATED
P02_SEMANTIC_GRAPH           = DEMONSTRATED
P03_CLASSIC_PRIMITIVE        = NOT_DEMONSTRATED
P04_CLASSIC_OWNED_ANCHOR     = NOT_DEMONSTRATED
P05_MULTI_EPOCH              = NOT_DEMONSTRATED
P06_FILE_CLASSIFICATION      = NOT_DEMONSTRATED
P07_DECISION_STACK           = NOT_DEMONSTRATED
P08_REPO_PARITY              = NOT_DEMONSTRATED
P09_CORPUS_PARITY            = NOT_DEMONSTRATED
```

## Status rule

Commit labels, roadmap text, TODOs, and directory names do not satisfy gates.

Only reproducible evidence under:

```text
evidence/phases/<PHASE>/
```

may change a phase from `NOT_DEMONSTRATED`.

When a phase passes, set `CURRENT_PHASE` to the next phase. When it does not
pass, leave `CURRENT_PHASE` unchanged and record the failed/partial result.
