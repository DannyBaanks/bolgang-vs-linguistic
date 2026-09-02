# P03-P05 — Classic Primitive, Anchors, Epochs

## P03

Demonstrate one runtime-dependent operation in ordinary Classic Malbolge.

Bad:

```text
input ignored -> prints known expected output
```

Good:

```text
runtime input changes operation result through Malbolge semantics
```

## P04

Implement Malbolge-owned continuation.

No host semantic decoding.

## P05

Minimum ceremony:

```text
same program hash
VM PID A -> anchor A -> dead
VM PID B -> anchor B -> dead
VM PID C -> final
```

Also prove fresh process state by terminating each process before next launch.

## Gates

```text
P03_CLASSIC_PRIMITIVE = DEMONSTRATED
P04_CLASSIC_OWNED_ANCHOR = DEMONSTRATED
P05_MULTI_EPOCH = DEMONSTRATED
```
