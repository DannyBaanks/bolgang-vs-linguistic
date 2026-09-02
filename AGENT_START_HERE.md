# AGENT START HERE

You are implementing **BOLGANG VS LINGUISTIC**.

Do not begin by rewriting Linguist.
Do not begin by porting Ruby.
Do not assume an anchor design works.

## First commandment

```text
NEVER GUESS.
```

If a property is not demonstrated by code, execution, trace, hash, fixture,
or independent reproduction:

```text
NOT_DEMONSTRATED
```

## Work order

1. Read:
   - `CLAIM_FIREWALL.md`
   - `ROADMAP.md`
   - `architecture/EXECUTION_MODEL.md`
   - `evidence/EVIDENCE_CONTRACT.md`
2. Run `scripts/discover_local_inputs.ps1`.
3. Freeze exact local provenance for:
   - the GitHub Linguist source/checkout used as oracle
   - Classic Malbolge interpreter(s)
4. Execute **PHASE 00 ONLY**.
5. Write its result under `evidence/phases/P00/`.
6. If P00 passes, continue to P01.
7. Stop at the first failed gate or `NOT_DEMONSTRATED`.
8. Never silently weaken a gate.
9. Implementation methodology is OUT_OF_PUBLIC_SCOPE.

## Git discipline

One phase = one coherent commit after its gate is satisfied.

Suggested messages:

```text
P00: freeze oracle and local provenance
P01: capture canonical linguist behavior corpus
P02: extract semantic process graph
P03: demonstrate first classic malbolge primitive
...
```

Do not commit generated gigabytes or vendor caches unless the evidence contract
requires the exact artifact.

## Required stop behavior

When a requested phase passes:

1. State `PHASE_X = DEMONSTRATED`.
2. Give exact evidence paths/hashes.
3. State the next phase.
4. STOP.

Do not automatically begin unrelated work.
