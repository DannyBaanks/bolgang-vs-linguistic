# AGENT START HERE

You are implementing **BOLGANG VS LINGUISTIC**.

## First commandment

```text
NEVER GUESS.
```

If a property is not demonstrated by code, execution, trace, hash, fixture,
or independent reproduction:

```text
NOT_DEMONSTRATED
```

## Permanent project contracts

Read:

1. `PROJECT_STATUS.md`
2. `CLAIM_FIREWALL.md`
3. `ROADMAP.md`
4. `architecture/EXECUTION_MODEL.md`
5. `evidence/EVIDENCE_CONTRACT.md`

These files are persistent project state.

## Disposable phase packet

The detailed instructions for the **one currently authorized phase** live in:

```text
_NEXT_PHASE/NEXT.md
```

`_NEXT_PHASE/` is local-only, ignored by Git, disposable, and MUST NOT become
part of public project history.

If `_NEXT_PHASE/NEXT.md` does not exist:

```text
NO_AUTHORIZED_NEXT_PHASE
```

STOP. Do not infer a phase from the roadmap and do not invent work.

If it exists:

1. read every file named by `_NEXT_PHASE/NEXT.md`;
2. execute exactly that phase;
3. obey all permanent claim/evidence contracts;
4. stop at the first failed gate or `NOT_DEMONSTRATED`;
5. write permanent evidence under `evidence/phases/<PHASE>/`;
6. update `PROJECT_STATUS.md`;
7. regenerate `ROADMAP_SHA256.json`;
8. delete `_NEXT_PHASE/`;
9. show the final diff/status;
10. commit only the permanent project changes;
11. STOP.

## Phase discipline

A commit name is not evidence.

A phase is demonstrated only when its gate has reproducible evidence in the
repository.

Never silently weaken a gate to make a phase pass.

## Git discipline

One demonstrated phase = one coherent commit.

Do not commit:
- `_NEXT_PHASE/`,
- local discovery output,
- caches/vendor junk,
- generated gigabytes not required by the evidence contract.

## Host boundary

The frozen central law remains in `CLAIM_FIREWALL.md`.

Implementation methodology that is not required to reproduce the public claim
is OUT_OF_PUBLIC_SCOPE.
