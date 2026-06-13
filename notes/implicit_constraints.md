# Implicit Constraints in SystemRDL: Conditions That Should Be Errors

## Overview

The SystemRDL 2.0 specification defines numerous rules for combining field properties (Section 9.6.1 and elsewhere), but many semantically contradictory combinations are not explicitly addressed. This document collects such cases where the specification is silent, but treating the combination as an error is justified.

Policy:

- Violations of `shall` rules in the specification are obviously errors (out of scope for this document).
- Combinations not addressed by the specification but logically contradictory based on property semantics are treated as errors.
- Combinations classified as "Undefined" by the specification are also treated as errors.

Items are listed in the order they appear in the specification (9.4 → 9.6 → 9.7).

---

## 1. SW Write Loss Due to Missing `we`/`wel` (Extension to `hw=rw`)

### Background

Per specification Section 9.4.1 (c), any hardware-writable field (`hw=w` or `hw=rw`) is continuously driven by hardware on every clock cycle when no write enable is specified:

> All hardware-writable fields shall be continuously assigned unless a write enable is specified.

In this case, any value written by software is immediately overwritten by hardware on the next cycle, causing **software writes to be lost**.

Section 9.4.1 (d) explicitly flags part of this problem as an error:

> When a field is writable by software and write-only by hardware (but not write-enabled), all software writes shall be lost on the next clock cycle. This shall reported as an error.

However, this rule uses the phrase "write-only by hardware", which strictly applies only to `hw=w`. The `hw=rw` case is not covered.

### Specification Coverage

- **`sw ∈ {w, rw}` + `hw=w` + no `we`/`wel`**: Explicit error per 9.4.1 (d).
- **`sw ∈ {w, rw}` + `hw=rw` + no `we`/`wel`**: Not addressed by the specification.

### Rationale (Extension to `hw=rw`)

The same technical problem occurs with `hw=rw`:

- Section 9.4.1 (c) mandates continuous assignment regardless of whether `hw=w` or `hw=rw`.
- Software writes are overwritten on the next cycle and lost.
- From the software's perspective, the write has no effect.

While `hw=rw` allows hardware to read the field, this does not imply that hardware preserves software-written values. The default behavior is continuous assignment, which destroys software writes just as it does with `hw=w`.

The omission of `hw=rw` from 9.4.1 (d) is best interpreted as an oversight: the problem is identical in both cases, and there is no apparent reason to flag only `hw=w`.

### Error Condition

`sw ∈ {w, rw}` AND `hw ∈ {w, rw}` AND neither `we` nor `wel` is set.

Notes:

- `sw=w` + `hw=w` is independently flagged as "Error – meaningless" in Table 12.
- `sw=rw` + `hw=w` is the explicit error case in 9.4.1 (d).
- `sw=w` + `hw=rw` and `sw=rw` + `hw=rw` are the extensions defined here.

---

## 2. "Undefined" Combinations in Table 12

### Background

Specification Table 12 classifies the following combinations of `sw=na` with HW read access as "Undefined":

- `sw=na, hw=rw`
- `sw=na, hw=r`

These entries lack the `Error -` prefix used for "Error – meaningless", "Error – unloaded net", and "Error – nonexistent net".

### Specification Coverage

"Undefined" — behavior is left to the implementation. Not explicitly flagged as an error.

### Rationale

- A field invisible to CSR access (hardware-internal only) has no meaningful interpretation as a register.
- Tool behavior should be predictable; treating these as errors avoids implementation-specific surprises.
- Distinguishing "Error" and "Undefined" complicates error reporting without practical benefit.

### Treatment

All 6 non-valid combinations in Table 12 (2 meaningless + 2 undefined + 1 unloaded net + 1 nonexistent net) are uniformly treated as "invalid sw/hw access combination" errors.

---

## 3. `swwe` / `swwel` Requires `sw = rw`

### Background

Specification 9.6.1 (d) example:
> if a field is declared as `sw=rw`, has a `swwe` property, and the value is currently false, the effective software access property is `sw=r`.

The purpose of `swwe`/`swwel` is to dynamically gate write access. When gated off, the field's effective access degrades from write-capable to read-only.

### Specification Coverage

Section 9.6.1 (d) uses `sw=rw` only as an example and does not impose any explicit constraint on the `sw` value. Section 9.6.1 (e) specifies only the mutual exclusion of `swwe` and `swwel`.

### Rationale

| `sw` | Meaning of `swwe`/`swwel` | Validity |
| --- | --- | --- |
| `sw=rw` | enabled → rw, disabled → r | **Only valid case** |
| `sw=w` | enabled → w, disabled → **na** (violates Table 12) | Invalid |
| `sw=r` | No write access to gate | Meaningless |
| `sw=na` | Already rejected by Table 12 | N/A |

`swwe`/`swwel` is only meaningful with `sw=rw`. All other combinations are semantically contradictory.

### Error Condition

`swwe = true` OR `swwel = true`, AND `sw ≠ rw`.

---

## 4. `singlepulse` Constraints

`singlepulse` has the behavior: a software write of 1 causes the field to assert for one cycle, then automatically clear back to 0. Section 9.6.1 (g) explicitly mandates `fieldwidth = 1` and `reset = 0`, which indicates that `singlepulse` is a **storage-based, value-oriented property** (a pure derived-signal property like `anded`/`ored` would not require a reset specification).

The semantics are:

- The field has 1-bit storage.
- On reset: value is 0.
- On software write of 1: value asserts (=1) for one cycle.
- Next cycle: value automatically returns to 0.
- **The field value itself is the pulse signal.**

This value-based interpretation entails several semantic constraints.

### 4.1 SW Access Must Include Write

#### Background

`singlepulse` is triggered by a software write of 1. With `sw=r` or `sw=na`, software cannot write, so the pulse can never be triggered.

#### Specification Coverage

No explicit rule.

#### Rationale

- Specifying `singlepulse` without software write capability is logically meaningless.
- Same spirit as "meaningless" / "unloaded net" cases in Table 12.

#### Error Condition

`singlepulse = true` AND `sw ∉ {w, rw}`.

---

### 4.2 Conflict with `onwrite` / `woset` / `woclr`

#### Background

`singlepulse` defines the field's value behavior on software write (assert for one cycle, then auto-clear). The `onwrite` property (including its shorthand forms `woset` and `woclr`) also defines field value behavior on software write. Specifying both creates a conflict in write-time behavior.

#### Specification Coverage

No explicit rule. Section 9.6.1 (k) mandates mutual exclusion among `onwrite`, `woclr`, and `woset`, but does not include `singlepulse`.

#### Rationale

- Two competing mechanisms define write-time field value behavior, with no defined precedence.
- No legitimate use case (likely a typo or misunderstanding).

#### Error Condition

`singlepulse = true` AND any of `onwrite`, `woset`, `woclr` is true.

---

## 5. `we` / `wel` Requires `hw = w` or `hw = rw`

### Background

Specification Section 9.7 introduction:
> Hardware access properties can be applied to fields to determine **when hardware can update a hardware writable field** (`we` and `wel`), ...

Specification 9.7.1 (a) (b):
> a) `we` determines this field is hardware-writable when set, resulting in a generated input which enables hardware access.
> b) `wel` determines this field is hardware-writable when not set, ...

`we`/`wel` is a mechanism for dynamically gating hardware writes, and **presupposes that the field is hardware-writable**.

### Specification Coverage

Section 9.7 introduction and 9.7.1 (a)(b) describe `we`/`wel` as mechanisms for "hardware-writable fields", but do not include an explicit `shall have ... access` rule comparable to 9.6.1 (i)(l) for `onread`/`onwrite`. Section 9.7.1 (c) only specifies the mutual exclusion of `we` and `wel`.

### Rationale

| `hw` | Meaning of `we`/`wel` | Validity |
| --- | --- | --- |
| `hw=w` | enabled → writable, disabled → write stopped | Valid |
| `hw=rw` | enabled → read/write, disabled → read-only | Valid |
| `hw=r` | No write access to gate | Meaningless |
| `hw=na` | No hardware interface at all | Meaningless |

This is symmetric with the relationship between `swwe`/`swwel` and `sw` (see Section 3): **a property that gates write access presupposes the existence of write capability**.

### Error Condition

`we = true` OR `wel = true`, AND `hw ∉ {w, rw}`.

---

## 6. Mutual Exclusion of Field Type Properties

### Background

SystemRDL provides several properties that designate a field as a special-purpose field. These are positioned as "special purpose fields" in the specification, each defining the field's semantic type:

| Property | Field Semantics | Specification |
| --- | --- | --- |
| `singlepulse` | Pulse-generating field (SW write 1 → 1-cycle assert → auto-clear) | Table 14, 9.6.1 (g) |
| `intr` | Interrupt field (event latch, sticky behavior) | Table 21, 9.9 |
| `counter` | Counter field (incremental/decremental accumulation) | Table 19, 9.8 |

These three properties each define field value behavior with **different and incompatible semantics**. They cannot meaningfully coexist on the same field.

### Specification Coverage

Related rules in the specification:

- Section 9.8 introduction positions `counter` as a "special purpose field".
- Section 9.9 defines interrupt field semantics.
- Section 9.6.1 (g) mandates `fieldwidth = 1` and `reset = 0` for `singlepulse`.

However, **no specification rule explicitly states that these three properties are mutually exclusive**.

### Rationale

All three properties determine "what kind of field this is", and combining them produces:

- **Multiple conflicting semantics defining the field value behavior with no defined precedence**:
  - `singlepulse` + `intr`: auto-clear vs. sticky retention
  - `singlepulse` + `counter`: auto-clear vs. count value retention
  - `intr` + `counter`: event latch vs. count accumulation
- **`singlepulse` + `counter`** is also structurally incompatible: the `fieldwidth = 1` requirement (9.6.1 g) conflicts with the multi-bit nature of counters.
- No legitimate use case (likely a typo or misunderstanding).

The absence of explicit specification rules is most naturally interpreted as an omission. Reading the specification's description of each special-purpose field makes clear that each is an independent field type, and the mutual exclusion follows directly from their semantics.

### Error Condition

Two or more of `singlepulse`, `intr`, `counter` are set to `true`.

Specifically:

- `singlepulse = true` AND `intr = true`
- `singlepulse = true` AND `counter = true`
- `intr = true` AND `counter = true`

---

## 7. Edge Cases (Under Consideration)

The following cases are not yet definitively classified as errors but are noted for future evaluation:

### 7.1 Consistency of `intr`-Related Properties

Semantic consistency between aggregation properties (`intr`, `anded`, `ored`, `xored`) and the field declaration.

---

## Validation Timing

All checks must run at both of the following phases, consistent with the dynamic assignment rules in Section 5.1.3.3 of the specification:

1. **At instance creation (`validate`)** — covers assignments in the definition body, instance-trailing `= value`, and default inheritance.
2. **After dynamic assignment (`revalidate`)** — covers assignments of the form `inst->prop = value`.

---

## Reference: Errors Explicitly Mandated by the Specification (Out of Scope)

The following are explicit `shall` rules in the specification and therefore not covered by this document:

- Default continuous assignment of hardware-writable fields (9.4.1 c)
- Error case of `sw=rw` + `hw=w` + no write enable (9.4.1 d)
- "Error" entries in Table 12
- Prohibition of duplicate property assignments within a scope (5.1.3.1, 5.1.3.3)
- Mutual exclusion of `swwe` and `swwel` (9.6.1 e)
- `fieldwidth` and reset constraints on `singlepulse` (9.6.1 g)
- Mutual exclusion of `onread`, `rclr`, and `rset` (9.6.1 h)
- `onread` requires software read access (9.6.1 i)
- External field requirement for `onread = ruser` (9.6.1 j)
- Mutual exclusion of `onwrite`, `woclr`, and `woset` (9.6.1 k)
- `onwrite` requires software write access (9.6.1 l)
- External field requirement for `onwrite = wuser` (9.6.1 m)
- Mutual exclusion of `we` and `wel` (9.7.1 c)
- Mutual exclusion of `hwenable` and `hwmask` (9.7.1 d)
- `fieldwidth` consistency (9.7)
