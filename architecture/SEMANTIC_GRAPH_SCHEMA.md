# SEMANTIC_GRAPH_SCHEMA

This is the machine-readable schema used by `evidence/phases/P02/semantic_graph.json`.
It freezes how the graph is built from the P01 corpus traces.

---

## Canonical graph

`evidence/phases/P02/semantic_graph.json` is produced by `scripts/p02_build_semantic_graph.py`
from a normalized trace run. Same trace in -> same graph out.

Semantic operations are nodes. An operation is a public behavior in the frozen
Linguist upstream; the vocabulary is derived from the frozen source and from what
the P01 corpus actually exercised. Nodes are NOT Ruby method names; they are
semantic steps (e.g. `strategy.modeline`, `flag.vendored`, `repo.languages_aggregate`).

### Node fields

Each node is an object with exactly these keys (materialized by the reducer):

```json
{
  "id": "string",
  "semantic_operation": "string",
  "required_inputs": ["string"],
  "state_reads": ["string"],
  "state_writes": ["string"],
  "immutable_data_dependencies": ["string"],
  "successors": ["string"],
  "observed_frequency": "integer",
  "cases_observed_in": ["string"]
}
```

Rules the reducer enforces:

- `id` is semantic and stable; derivation of id does not depend on randomness.
- `required_inputs` only names the data a node actually consumed (as observed
  by a trace event in some case).
- `state_reads` / `state_writes` enumerate logical state the node reconciled
  with upstream. Pure code paths use `[]`.
- `immutable_data_dependencies` is a set of pinned relative filenames in the
  frozen upstream checkout; each listed file is hashed in
  `evidence/phases/P02/data_dependencies.json`.
- `successors` is a deterministic set of subsequent operation IDs.
- `observed_frequency` is a count derived from trace entries; counting unit
  documented in the graph's `counting_unit` field.
- `cases_observed_in` lists the P01 case IDs that produced at least one event
  for this operation.

### Edges

`edges` is a list of `{from, to, count}` triples. An edge exists iff at least
one normalized trace contained that ordered pair.

### Frequency

`observed_frequency` counts one wrapped upstream call frame, i.e. `one trace event entry`.

### Canonical JSON normalization

- Keys sorted; UTF-8; LF; one terminating newline.
- No timestamps, no absolute paths, no host names, no random IDs.

Constraint: this schema is only about the frozen P01 corpus coverage;
anything not exercised is simply absent.

## Related

- `evidence/phases/P02/source_map.json` — per-operation upstream provenance.
- `evidence/phases/P02/data_dependencies.json` — frozen immutable data files with sha256.
- `evidence/phases/P02/coverage.json` — per-section coverage over the P01 corpus.
