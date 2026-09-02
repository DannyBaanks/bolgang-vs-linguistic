# Master Roadmap

Detailed execution instructions are intentionally **not** stored here.
The currently authorized phase is supplied through a local disposable
`_NEXT_PHASE/` packet. This file freezes only the public phase order and gates.

A roadmap entry is a target, not evidence.

```text
TRACK A — make it work
```

---

## P00 — Freeze provenance and definitions

Goal:
- freeze Linguist oracle checkout,
- freeze Classic Malbolge interpreters,
- define exact observable outputs.

Gate:
`P00_PROVENANCE_FROZEN = DEMONSTRATED`

## P01 — Canonical Linguist oracle corpus

Build a small-to-large deterministic corpus covering:
- extension,
- filename,
- aliases/types where observable,
- shebang/modeline,
- ambiguous extensions/heuristics,
- vendor/generated/documentation classification where relevant,
- repository byte aggregation.

Capture upstream outputs as immutable oracle evidence.

Gate:
`P01_ORACLE_CORPUS = DEMONSTRATED`

## P02 — Semantic process graph

Extract a behavior-oriented graph, not a Ruby-AST dump.

Each node records:
- semantic operation,
- required inputs,
- state read/write,
- immutable data touched,
- successors,
- observed frequency.

Output:

```text
G_LINGUIST = (states, transitions, data dependencies)
```

Gate:
`P02_SEMANTIC_GRAPH = DEMONSTRATED`

## P03 — First Classic Malbolge primitive

Implement the smallest useful semantic primitive in ordinary Classic Malbolge.

Examples:
- byte comparison,
- deterministic table scan,
- suffix match,
- integer accumulator.

It must consume runtime data, not print a precomputed answer.

Gate:
`P03_CLASSIC_PRIMITIVE = DEMONSTRATED`

## P04 — Malbolge-owned anchor V1

Classic Malbolge must:
- decide to checkpoint,
- canonicalize logical state,
- encode anchor,
- include integrity,
- HALT.

Fresh Classic VM must:
- validate anchor,
- decode,
- resume.

Host only stores exact bytes.

Gate:
`P04_CLASSIC_OWNED_ANCHOR = DEMONSTRATED`

## P05 — Multi-epoch semantic program

Same immutable `.mal` artifact.
At least 3 fresh VM processes.
Distinct dead PIDs.
Same logical operation continues across boundaries.

Gate:
`P05_MULTI_EPOCH = DEMONSTRATED`

## P06 — One real Linguist decision through epochs

Choose one nontrivial classification case.
All semantic decisions occur in Classic Malbolge.
Compare to upstream oracle.

Gate:
`P06_FILE_CLASSIFICATION = DEMONSTRATED`

## P07 — Linguist decision stack

Add in increasing order:
1. extension/filename candidate lookup
2. shebang/modeline
3. ambiguous heuristics
4. generated/vendor/doc filters needed by frozen corpus
5. byte-count aggregation

Gate:
`P07_DECISION_STACK = DEMONSTRATED`

## P08 — Repository-level process

Run a small frozen repository fixture end-to-end.

Output equality must be defined canonically before testing.

Gate:
`P08_REPO_PARITY = DEMONSTRATED`

## P09 — Frozen corpus parity

Run the complete frozen observable corpus.

Record:
- upstream result hash,
- Malbolge result hash,
- epoch count,
- all anchor hashes,
- process IDs,
- wall time,
- exact Classic interpreter(s).

Gate:
`P09_CORPUS_PARITY = DEMONSTRATED`

At this point the defensible claim is:

> Observable Linguist behavior exercised by the frozen corpus executes through
> ordinary Classic Malbolge epochs.

This is already a successful project.
