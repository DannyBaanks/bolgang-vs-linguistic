# Anchor Protocol Requirements

The exact wire format is intentionally NOT designed here.
The implementation phase must derive it from demonstrated needs.

Minimum properties:

```text
MAGIC / VERSION
logical continuation payload
integrity field
explicit termination / continuation mode
```

## Ownership

Classic Malbolge owns:
- checkpoint trigger,
- canonicalization,
- payload construction,
- integrity construction,
- validation,
- decoding,
- resume transition.

Host owns:
- exact byte capture,
- exact byte persistence,
- exact byte replay.

## Required tests

A valid anchor suite must include:

1. same immutable `.mal` artifact across all epochs
2. >= 3 fresh process boundaries
3. all old processes dead before resume
4. exact resume equivalence against no-restart reference for a small model
5. one-bit/one-byte corruption rejection
6. truncated anchor rejection
7. wrong-version rejection
8. restart machine/process between epochs
9. optional cross-interpreter handoff if two independent Classic VMs are available

## Failure

If Python/Rust/Ruby decodes the logical payload to reconstruct state:

```text
HOST_STOLE_COMPUTATION
P04 = FAIL
```
