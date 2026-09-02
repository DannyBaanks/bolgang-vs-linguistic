# Execution Model

## Physical vs logical execution

Track A distinguishes:

```text
ONE_PHYSICAL_VM_RUN = bounded Classic Malbolge incarnation

ONE_LOGICAL_LINGUIST_RUN =
sequence of bounded Classic Malbolge incarnations connected by
Malbolge-owned continuation state
```

No claim that Classic Malbolge physically contains unbounded memory is allowed.

## Epoch model

```text
raw input / opaque anchor
        |
        v
+-----------------------+
| fresh Classic VM      |
| exactly 59049 cells   |
|                       |
| decode state          |
| execute work          |
| decide checkpoint     |
| encode next anchor    |
+-----------------------+
        |
        +--> final answer
        |
        +--> opaque anchor -> host byte store -> fresh VM
```

## Host as cable

Allowed host state:

```text
artifact_path
interpreter_path
opaque_anchor_bytes
raw_input_bytes
pid/timing/log metadata
```

Forbidden host state:

```text
current_language_candidate
heuristic_result
decoded_anchor_state
Linguist accumulator semantics
precomputed next transition
```

## Input streaming

Large input repositories do not need to reside entirely in the 59049 cells.

The host may provide an exact deterministic byte stream.

It must not transform:

```text
foo.rb
```

into:

```text
candidate_language = Ruby
```

The semantic interpretation belongs to Malbolge.
