PHASE: P00
STATUS: DEMONSTRATED

## Claim

The environment for Malbolge-vs-Linguist behavior comparison is frozen: the
Linguist oracle revision, two independent Classic Malbolge interpreters, a
known-vector pass, the observable-result normalization, and the host boundary
are all recorded with exact hashes and provenance.

## Inputs

- GitHub Linguist oracle checkout (local, see `commands.txt` for placeholders):
  remote `github-linguist/linguist`.
  Pristine upstream `origin/main` = `d5214e1612c858ba14bf98edeca57e1683276f1d`.
  Working oracle HEAD = `b88d632053392ec83fdb00cdc2a39ac3cabb301c` on branch
  `malbolge-patch-canonical` (pristine upstream + ONE Malbolge patch commit
  whose parent is exactly the pristine commit). Clean working tree.
- Classic interpreter #1 (reference): `malbolge-oracle/oracle.py`
  (Iizawa 2005 Appendix C semantics, no shared ancestry with runtimes).
- Classic interpreter #2 (independent C VM): `gost/gost.exe` built from
  `gost/gost.c`.
- Known vector: `upstream/samples/Malbolge/truth_machine.malbolge` (a Malbolge
  truth machine, 2-way input branch primitive).

## Commands

See `commands.txt`. Exact local paths are redacted; identity is carried by
commit SHAs and SHA-256 hashes.

## Artifacts and hashes

- Linguist oracle commit `d5214e1612c858ba14bf98edeca57e1683276f1d`
  (pristine upstream main).
- Linguist oracle commit `b88d632053392ec83fdb00cdc2a39ac3cabb301c`
  (working oracle HEAD, Malbolge patch on top of pristine).
- oracle.py SHA256 `e7e71a24a7560aed944f178784567fda29afb228fcd91a41e8ed41c13430bf8d`
- gost.c SHA256 `acbe79047d797dad4e9dcacb97399ee3ad24cb2bae8b7e11d51ce110b4d09588`
- gost.exe (built) SHA256 — see `hashes.json`
- truth_machine.malbolge SHA256 `7062713e96dae33f5672fc4dcd654d5657e3c0ab44fd03bd93ebdd3ec43feb82`

## Observed

- oracle (interpreter #1) on truth_machine with input `0`:
  `steps=136`, `halted=True`, `halt_reason=halt_opcode`, `output='0'`.
- gost (interpreter #2) on truth_machine with input `0`:
  exit `0`, STDOUT `0`, stderr metadata `steps=136 ... terminated=yes`.
- Both independent Classic interpreters agree: 136 steps, output `0`.

## Not observed

- Independent interpreter #2 differs from #1 on the known vector: NOT OBSERVED
  (they agree).
- Any deviation from Classic 10-trit / 59049-cell semantics: NOT OBSERVED.

## Confounds

- oracle repo had a dirty working tree (`M README.md`) at its recorded commit
  `6cf2423f1827290b12fb46d60102a944f5793eba`. The README change does not alter
  `oracle.py` semantics (oracle.py hash is the frozen artifact).
- gost's stderr metadata line prints `output=1`; this is an internal flag in
  gost's report and is NOT the program stdout. The program stdout is `0`.

## Gate

```
LINGUIST_ORACLE_REVISION_FROZEN = TRUE
CLASSIC_INTERPRETER_1_FROZEN    = TRUE
CLASSIC_KNOWN_VECTOR_PASS       = TRUE
NORMALIZATION_FROZEN            = TRUE
HOST_BOUNDARY_FROZEN            = TRUE
```

## Next action

P00_PROVENANCE_FROZEN = DEMONSTRATED. Next gate is P01_ORACLE_CORPUS.