# Counter Trigger Reference Policy

## Overview

This document records this implementation's policy on the `incr` and `decr`
properties of counter fields, focusing on the width of the reference target
and the semantics when a multi-bit reference is supplied. It identifies the
silent area in the specification and states the chosen interpretation together
with its justification.

---

## 1. Specification Text

Specification 9.8.1 defines `incr` and `decr` as follows:

> Additionally, the properties `incr` and `decr` can be used to control the
> increment and decrement events of a counter. These do not control the
> increment or decrement values, as `incrvalue` and `decrvalue`, but the
> actual increment of the counter (as shown in Example 2). These properties
> can be only be assigned as references to another component.

Table G1 lists both properties with `Type = instance reference` and
`Ref target = y`.

Two things are established by the specification:

- `incr` / `decr` are events (triggers), not values. Increment/decrement
  amounts are the job of `incrvalue` / `decrvalue`.
- They shall be assigned as references to another component (a field or a
  signal, per each property's usage; see Section 4).

The specification does **not** state the required bit width of the reference
target. Example 2 uses a 1-bit `overflow` net, but this is an example, not a
normative constraint.

---

## 2. Silent Area

Because the specification does not restrict the reference target's width, at
least the following are underspecified:

- Whether the target must be exactly 1 bit wide.
- If a multi-bit target is permitted, what its bits mean with respect to the
  counter's increment/decrement event.

Existing implementations diverge here. The `systemrdl-compiler` reference
implementation restricts the target to 1 bit (`_validate_ref_width_is_1`).
Nothing in the specification requires this narrowing.

---

## 3. Chosen Interpretation

### 3.1 Width

The reference target of `incr` / `decr` shall be at least 1 bit wide. No upper
bound is imposed on the width.

The specification is silent, so no upper bound is imposed.

### 3.2 Multi-Bit Semantics: Population Count

When the reference target is *N* bits wide (*N* >= 1), each bit of the target
is treated as an independent event line for the counter. In a given cycle,
the counter is incremented (or decremented) by the number of bits currently
asserted on the target -- that is, the population count of the target's
current value.

Combined with `incrvalue` / `decrvalue` (call the step *K*, defaulting to 1
when not specified), the counter's per-cycle change is:

- `incr`: `+ popcount(incr_target) * incrvalue`
- `decr`: `- popcount(decr_target) * decrvalue`

For the 1-bit case (*N* = 1) this reduces to the ordinary behavior: the
counter changes by *K* when the single line is asserted and does not change
otherwise. Multi-bit targets are a strict generalization.

### 3.3 Why Population Count Rather Than OR

An OR-reduction interpretation ("increment once if any bit is asserted") is
also consistent with the spec's silence, but it provides no capability that
SystemRDL cannot already express: a user who wants OR-reduction can supply a
1-bit signal, or use the `ored` property of a field, and connect that 1-bit
result. Allowing a multi-bit target only to fold it back to 1 bit adds
nothing.

Population count, by contrast, expresses something the language otherwise
cannot: "several event sources sharing one counter, counted accurately even
when multiple sources fire in the same cycle." This matches the realistic
use case of aggregating multiple error types, interrupt sources, or
performance events into a single counter.

The semantics are also well-defined and predictable: `popcount` is a standard
operation.
