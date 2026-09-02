# P01-P02 — Oracle Corpus and Semantic Graph

## P01 corpus progression

Start tiny, then adversarial:

```text
single obvious extension
filename-specific rule
same extension with conflicting candidates
shebang
modeline
ambiguous heuristic
generated/vendor/doc cases
small repository aggregation
```

Freeze input bytes and upstream outputs before implementing Malbolge behavior.

## P02 graph extraction

Do not model Ruby objects unless they are semantically necessary.

Node example:

```json
{
  "id": "CHECK_EXTENSION",
  "reads": ["path_suffix", "language_table"],
  "writes": ["candidate_set"],
  "successors": ["CHECK_FILENAME", "CHECK_SHEBANG"],
  "immutable_data": ["extension_index"]
}
```

Graph extraction must distinguish:
- semantic state,
- transport state,
- presentation state.

## Gates

```text
P01_ORACLE_CORPUS = DEMONSTRATED
P02_SEMANTIC_GRAPH = DEMONSTRATED
```
