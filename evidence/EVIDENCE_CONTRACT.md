# Evidence Contract

Every demonstrated phase gets:

```text
evidence/phases/<PHASE>/
    RESULT.md
    commands.txt
    environment.json
    hashes.json
    raw_stdout.txt
    raw_stderr.txt
```

Add binary/trace artifacts only when needed to reproduce the result.

## RESULT.md fields

```text
PHASE:
STATUS: DEMONSTRATED | PARTIAL | NOT_DEMONSTRATED | CONFOUNDED
CLAIM:
INPUTS:
ARTIFACTS:
COMMANDS:
OBSERVED:
NOT_OBSERVED:
CONFOUNDS:
NEXT_GATE:
```

## Hash rule

SHA256 at minimum for:
- upstream oracle revision/bundle metadata,
- Classic Malbolge program,
- input corpus manifest,
- result output,
- every anchor in anchor tests.

## Differential oracle rule

For behavior claims:

```text
UPSTREAM(input) -> A
MALBOLGE(input) -> B
```

Store canonical normalized A and B.

The normalization itself must be frozen and non-semantic.

Then:

```text
A == B
```

is evidence.

## Runtime proof

For multi-epoch claims record:
- PID per epoch,
- start/end timestamp,
- artifact hash,
- interpreter hash/version,
- anchor in/out hashes,
- exit code.

## Negative evidence is valid

A phase that ends:

```text
NOT_DEMONSTRATED
```

with reproducible evidence is a successful experiment report.
Do not fabricate progress.
