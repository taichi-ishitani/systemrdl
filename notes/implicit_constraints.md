# Implicit Constraints in SystemRDL: Conditions That Should Be Errors

## Overview

The SystemRDL 2.0 specification defines numerous rules for combining field properties (Section 9.6.1 and elsewhere), but many semantically contradictory combinations are not explicitly addressed. This document collects such cases where the specification is silent, but treating the combination as an error is justified.

Policy:

- Violations of `shall` rules in the specification are obviously errors (out of scope for this document).
- Combinations not addressed by the specification but logically contradictory based on property semantics are treated as errors.
- Combinations classified as "Undefined" by the specification are also treated as errors.
- Combinations where a property's effect is simply nullified by other property settings (i.e., the property acts as a no-op) are not treated as errors, as long as the field itself still behaves correctly according to its other declared properties. Such cases are merely meaningless but cause no observable harm.
- Combinations where a property's primary purpose is silently defeated (i.e., the field cannot function as declared) are treated as errors. These are silent failures even if no incorrect value is produced.

Items are listed in the order they appear in the specification (9.4 -> 9.6 -> 9.7).

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

- **`sw in {w, rw}` + `hw=w` + no `we`/`wel`**: Explicit error per 9.4.1 (d).
- **`sw in {w, rw}` + `hw=rw` + no `we`/`wel`**: Not addressed by the specification.

### Rationale (Extension to `hw=rw`)

The same technical problem occurs with `hw=rw`:

- Section 9.4.1 (c) mandates continuous assignment regardless of whether `hw=w` or `hw=rw`.
- Software writes are overwritten on the next cycle and lost.
- From the software's perspective, the write has no effect.

While `hw=rw` allows hardware to read the field, this does not imply that hardware preserves software-written values. The default behavior is continuous assignment, which destroys software writes just as it does with `hw=w`.

The omission of `hw=rw` from 9.4.1 (d) is best interpreted as an oversight: the problem is identical in both cases, and there is no apparent reason to flag only `hw=w`. Note that this conclusion does not depend on the `precedence` property: `precedence` only selects the winner when software and hardware write in the same cycle, whereas the loss here is caused by hardware's continuous assignment overwriting the software value on the *following* cycle. The fact that 9.4.1 (d) flags `hw=w` unconditionally, without reference to `precedence`, confirms that `precedence` is irrelevant to this problem.

### Error Condition

`sw in {w, rw}` AND `hw in {w, rw}` AND neither `we` nor `wel` is set.

Notes:

- `sw=w` + `hw=w` is independently flagged as "Error - meaningless" in Table 12.
- `sw=rw` + `hw=w` is the explicit error case in 9.4.1 (d).
- `sw=w` + `hw=rw` and `sw=rw` + `hw=rw` are the extensions defined here.

---

## 2. "Undefined" Combinations in Table 12

### Background

Specification Table 12 classifies the following combinations of `sw=na` with HW read access as "Undefined":

- `sw=na, hw=rw`
- `sw=na, hw=r`

These entries lack the `Error -` prefix used for "Error - meaningless", "Error - unloaded net", and "Error - nonexistent net".

### Specification Coverage

"Undefined" - behavior is left to the implementation. Not explicitly flagged as an error.

### Rationale

- A field that is not accessible from software (`sw=na`) has no software interface, which is outside the purpose of a CSR description language; the specification itself declines to define these cases ("Undefined").
- Treating them as errors makes tool behavior predictable and avoids implementation-specific surprises.
- Distinguishing "Error" and "Undefined" in error reporting adds complexity without practical benefit.

Note: unlike the `shall`-derived errors elsewhere in this document, error-ing on "Undefined" is a deliberate implementation choice for predictability, not a behavior mandated by the specification.

### Treatment

All 6 non-valid combinations in Table 12 (2 meaningless + 2 undefined + 1 unloaded net + 1 nonexistent net) are uniformly treated as "invalid sw/hw access combination" errors.

---

## 3. `singlepulse` Constraints

`singlepulse` has the behavior: a software write of 1 causes the field to assert for one cycle, then automatically clear back to 0. Section 9.6.1 (g) explicitly mandates `fieldwidth = 1` and `reset = 0`, which indicates that `singlepulse` is a **storage-based, value-oriented property** (a pure derived-signal property like `anded`/`ored` would not require a reset specification). This value-based interpretation is reinforced by the fact that `singlepulse` cannot be used as the right-hand side of a property reference (Table G1): the pulse is not a separately routable output signal, but the field value itself.

The semantics are:

- The field has 1-bit storage.
- On reset: value is 0.
- On software write of 1: value asserts (=1) for one cycle.
- Next cycle: value automatically returns to 0.
- **The field value itself is the pulse signal.**

This value-based interpretation entails several semantic constraints.

### 3.1 SW Access Must Include Write

#### Background

`singlepulse` is triggered by a software write of 1. With `sw=r` or `sw=na`, software cannot write, so the pulse can never be triggered.

#### Specification Coverage

No explicit rule.

#### Rationale

- Specifying `singlepulse` without software write capability silently defeats the field's declared purpose (pulse generation): the pulse can never fire.
- A theoretically harmless reading exists (a constant-0 field that hardware reads), but in that case there is no reason to declare `singlepulse` at all, so the combination is almost certainly a mistake. This is treated as an error to catch the mistake, deliberately accepting that the rare harmless reading is also rejected.

#### Error Condition

`singlepulse = true` AND `sw not in {w, rw}`.

---

### 3.2 Conflict with `onwrite` / `woset` / `woclr`

#### Background

`singlepulse` defines the field's value behavior on software write (assert for one cycle, then auto-clear). The `onwrite` property (including its shorthand forms `woset` and `woclr`) also defines field value behavior on software write. Specifying both creates a conflict in write-time behavior.

#### Specification Coverage

No explicit rule. Section 9.6.1 (k) mandates mutual exclusion among `onwrite`, `woclr`, and `woset`, but does not include `singlepulse`.

#### Rationale

- Both define what the field value does on a software write, with no defined precedence between them. For example, on a write of 1, `woclr` requires the value to become 0 while `singlepulse` requires it to become 1 (then auto-clear) - a direct conflict.
- This conflict follows from interpreting `singlepulse` as value-based (see Section 3). A construction such as "clear on write, and additionally emit a pulse" cannot be expressed, because the pulse is the field value itself and is not a separate routable signal.
- No legitimate use case under the value-based interpretation; almost certainly a typo or misunderstanding.

#### Error Condition

`singlepulse = true` AND any of `onwrite`, `woset`, `woclr` is true.

---

## 4. Mutual Exclusion of Field Type Properties

### Background

SystemRDL provides several properties that designate a field as a special-purpose field. Each defines what kind of field it is by governing how the field's value behaves:

| Property      | Field Semantics                                                   | Specification       |
| ------------- | ----------------------------------------------------------------- | ------------------- |
| `singlepulse` | Pulse-generating field (SW write 1 -> 1-cycle assert -> auto-clear) | Table 14, 9.6.1 (g) |
| `intr`        | Interrupt field (event latch, status retention, aggregation)      | Table 20/21, 9.9    |
| `counter`     | Counter field (incremental/decremental accumulation)              | Table 19, 9.8       |

The position taken here is that these are mutually exclusive *field types*: a field is at most one of pulse, interrupt, or counter. Any combination of two or more is treated as an error, rejected during elaboration.

### Specification Coverage

Related rules in the specification:

- Section 9.8 introduction positions `counter` as a "special purpose field".
- Section 9.9 defines interrupt fields in a dedicated clause of their own.
- Section 9.6.1 (g) mandates `fieldwidth = 1` and `reset = 0` for `singlepulse`.

**No specification rule explicitly states that these three properties are mutually exclusive.** The mutual exclusion is an interpretation. The strength of the basis differs between the pairs, and is recorded below so that each can be revisited independently if a concrete need arises. Note that the layer at which the check is implemented (here, the elaborator) is a separate decision from the strength of the underlying justification; a moderately-grounded rule may still be enforced at the elaborator.

### Rationale

#### `singlepulse` + `counter` -- conflicting drive of `next` (semantic contradiction)

Both are storage-backed fields that drive the field's `next` (next-state) value. `counter` drives `next` as the incremented/decremented value; `singlepulse` drives `next` as a self-clearing pulse (1 for one cycle, then 0). The same `next` is defined by two independent rules at once, with no observer/observed split to separate them (both are drivers). The next-state of the field cannot be determined, so the combination is not coherent as SystemRDL, independent of any question of demand.

Note that this is *not* a width contradiction: the specification does not forbid a 1-bit counter, and a 1-bit counter is also `fieldwidth = 1`, so `singlepulse`'s width requirement alone does not exclude `counter`. The genuine conflict is in the drive of `next`.

This is the most firmly grounded of the three pairs: a semantic impossibility.

#### `intr` + `counter`, `intr` + `singlepulse` -- distinct field type (interpretation)

A coherent single-field reading can be constructed for each:

- `intr` + `counter`: the interrupt types in Table 20 are defined as functions of the field's `next` value, and a counter drives `next`; read this way, "interrupt while the count is non-zero" is coherent (the interrupt source being the bitwise OR, i.e. a non-zero test, of the field value).
- `intr` + `singlepulse`: with a `nonsticky` interrupt, `singlepulse` drives `next` and the interrupt observes it, giving a one-cycle pulse interrupt.

These readings, however, depart from the role `intr` is given by the specification. Section 9.9 defines the interrupt field in a dedicated clause, with status retention as a core part of its role: by default an interrupt is `stickybit`, latching the event (and, with `sticky`, an associated multi-bit value) until software clears it. Retention is what lets software observe an interrupt after the fact. The coherent readings above only work by stripping this role away:

- `intr` + `singlepulse` requires a `nonsticky` interrupt, because the default sticky retention directly conflicts with `singlepulse`'s self-clear. But `nonsticky` is itself intended (per 9.9) for *hierarchical aggregation* -- a relay stage whose `next` is fed by lower-level interrupt signals -- not for a leaf event source. `singlepulse` and `counter` are leaf event sources, where retention (sticky) is normally wanted; pairing them with `nonsticky` misplaces the aggregation role onto a leaf.
- In every such reading, nothing is expressed that could not be written more directly with a single one of these properties, or with the idiomatic split-field form (e.g. routing a counter's `incrthreshold`/`overflow` output to a separate `intr` field, as in 9.8.2). The combination carries no use that requires it.

The basis for rejecting these two pairs is therefore weaker than for `singlepulse` + `counter`: it is not a semantic impossibility, but an interpretation grounded in `intr` being defined as a self-contained field type in its own clause (9.9), reinforced by the absence of any same-field use that the combination uniquely enables. There is no explicit prohibition in the specification, and the coherent readings are acknowledged. The decision is nonetheless to reject these combinations during elaboration, treating `intr` as a distinct field type that does not combine with `counter` or `singlepulse`.

If a concrete use that genuinely requires one of these `intr` combinations materializes, this rejection should be revisited; because its basis is an interpretation rather than a semantic impossibility, it can be relaxed without contradicting the specification (unlike `singlepulse` + `counter`).

### Error Condition

Two or more of `singlepulse`, `intr`, `counter` are set to `true`.

Specifically:

- `singlepulse = true` AND `intr = true`
- `singlepulse = true` AND `counter = true`
- `intr = true` AND `counter = true`

---

## 5. `next` Interpreted as a Form of Hardware Write Data

### Background

The `next` property has type `reference` (Table 13) and is described as "the next value of the field; the D-input for flip-flops". It can be assigned a reference to another field, a signal, or a field's property output (e.g. `d->next = a`, `has_overflowed->next = count1->overflow`, `status.a->next = intr_reg->intr`). It cannot take an operation/expression as its right-hand side, because its type is `reference` and the result of an operation is a value, not a reference.

The specification says almost nothing about how `next` interacts with the software/hardware access settings. The only explicit `next` rules are: `next` and `reset` cannot be self-referencing (9.5 e), and `reset` has priority over `next` when the reset signal is asserted (9.5 f). There is no rule stating which `sw`/`hw` settings are required or forbidden when `next` is used.

### Interpretation

This implementation interprets `next` as a form of hardware write data: when `next` is assigned, the referenced source supplies the value that hardware writes into the field. Under this interpretation, `next` does not introduce a new value-driving mechanism distinct from hardware write; it specifies what data the hardware write path delivers, replacing the otherwise inferred input.

Consequences of this interpretation:

- `next` requires the field to be hardware-writable (`hw` is `w` or `rw`). Without a hardware write path, there is nowhere for the supplied value to be applied.
- The `sw`/`hw`/`we`/`wel` constraints that apply to ordinary hardware-writable fields apply to fields with `next` as well, since `next` is just a form of hardware write data.

### Rules

`next` requires the field to be hardware-writable (`hw in {w, rw}`). Without a hardware write path, the value supplied by `next` cannot be applied, which is a silent failure of the property's stated purpose (distinct from the no-op cases at the end of this document, since here a clear design intent is left unrealized).

Beyond this, the constraints on `sw`/`hw`/`we`/`wel` follow Section 1 (SW Write Loss) without modification, since `next` is just a form of hardware write data.

### Error Condition

`next` is set AND any of the following holds:

- `hw not in {w, rw}` (no hardware write path), or
- `sw in {w, rw}` AND neither `we` nor `wel` is set (Section 1 software-write-loss condition).

### Status of This Decision

The interpretation of `next` as a form of hardware write data is **not** a specification-mandated rule. The specification permits `next` as a general `reference`-typed property without specifying its interaction with `sw`/`hw`/`we`. The interpretation here is a deliberate choice that grounds `next` in the same model as ordinary hardware writes, so that the well-defined rule of Section 1 governs both. Other implementations may interpret `next` differently (for example, as a value-drive that overrides other mechanisms, or as resolved by `precedence` at runtime), and behavior may differ across tools in cases where this interpretation diverges from theirs.

If a use case requires `next` under a different interpretation, this decision should be revisited; because the basis is an interpretation rather than a specification rule, alternative readings would not contradict the specification.

---

## 6. Sub-Word Spanning of Side-Effect Fields (10.6.1 f Extension)

### Background

Specification 10.6.1 (f) states:

> Any field that is software-writable or clear on read shall not span multiple software accessible sub-words.

The purpose is to ensure that an access from software completes the update of the field within a single sub-word access. When a field spans sub-words, an update requires multiple accesses, leaving the field in an intermediate state between them.

### The Enumeration Is Incomplete

The rule names two cases: software-writable fields, and clear-on-read (`rclr`). However, several other field configurations also change the field value or trigger side effects in response to a software access, and they suffer from exactly the same problem if they span sub-words:

- `rset` (set on read) is symmetric to `rclr`; the read access changes the value, just to 1 instead of 0.
- `onread = ruser` (user-defined read side effect) attaches a side effect to the read access.

These are all members of the same category as `rclr` -- the read access has a side effect on the field. There is no apparent reason why `rclr` would require the rule and `rset` or `ruser` would not.

### Rationale

The literal enumeration in 10.6.1 (f) is treated as an incomplete listing. The rule is applied based on the purpose of (f) -- "any access that changes the field value or triggers a side effect must complete within a single sub-word" -- so the constraint covers software-writable fields and all `onread`-family fields (`rclr`, `rset`, `ruser`) uniformly.

### Error Condition

A field spans multiple software-accessible sub-words AND (field is software-writable OR `onread` is set to any of `rclr`, `rset`, `ruser`).

## 7. Alias Register Constraints

An alias register shares a single physical register with its primary (10.5 introduction). A change at one location is observable at all locations. This physical sharing underlies both of the constraints in this section: any difference between primary and alias must be realizable on the shared storage.

### 7.1 Property Changes Restricted to the Specified List (10.5.1 e)

#### Background

Specification 10.5.1 (b) states that an alias register's fields may have a different *type* from the primary's fields, as long as instance name, position, and size match. Clause 10.5.1 (e) then restricts which properties may actually differ between the alias and the primary:

> Only the following SystemRDL properties may be different in an alias: `desc`, `name`, `onread`, `onwrite`, `rclr`, `rset`, `sw`, `woclr`, `woset`, and any user-defined properties.

#### Rationale

The physical sharing constrains what can meaningfully differ:

- Properties that affect how software sees the register (`sw`, `onread`/`onwrite` and their shorthands, descriptive properties) can differ per location, because they are realized by the decode and read-modify logic of each access path; the underlying storage is unchanged.
- Properties that determine the hardware-side behavior of the register (e.g. `hw`, `we`/`wel`, `hwclr`/`hwset`, `next`, `reset`, counter/interrupt properties) are properties of the single physical implementation; they cannot meaningfully be made to differ between primary and alias.

The list in (e) is therefore best read as a refinement of (b): a field type may differ between primary and alias, but only insofar as the differences fall within the list in (e). Any difference outside that list (whether introduced by direct property assignment or implicit in a different field type) would attempt to change a property that is a property of the shared physical register, which is impossible to realize.

Note: this same rule applies whether the difference is stated as a direct alias-side property override or arises from declaring a different field type for the alias. The latter is permitted by (b), but the property-level differences it produces must still fall within the list in (e).

#### Error Condition

An alias register has a property differing from the corresponding primary register's property, where the differing property is not in the list of (e).

### 7.2 Alias Field Must Exist in Primary (10.5.1 b)

#### Background

Specification 10.5.1 (b) states that every field in the alias register must have the same instance name as a field in the primary register, and the two fields must have the same position and size.

The converse case -- an alias-side field that does not exist in the primary -- is not addressed by the specification. Clause 10.5.1 (c) only states that the alias is *not required* to have all the fields from the primary, addressing the case where the alias omits primary fields, but not the case where the alias adds new fields.

#### Rationale

The storage is the primary's. An alias-side field that has no corresponding primary field would refer to physical bits that do not exist in the shared register, which has no meaningful realization.

#### Error Condition

An alias register contains a field whose instance name does not match any field in the primary register.

#### See Also

The complementary case -- accessing positions where the alias has *omitted* a field that exists in the primary -- is a behavioral choice on the backend rather than an error, and is described in [alias_handling_policy.md](alias_handling_policy.md).

## 8. `intr` / `halt` Register Properties on the Left-Hand Side (10.8.1 a)

Specification 10.8.1 (a) states that the `intr` and `halt` register properties are *outputs* and should only occur on the right-hand side of an assignment.

These properties have type `N/A` (Table 23) -- they do not have a value type that can be the target of an assignment. An attempt to place `intr` or `halt` on the left-hand side of a property assignment is therefore caught by the general property-assignment type check, without requiring a dedicated rule.

This is recorded here for completeness; no separate check is implemented.

---

## 9. Edge Cases (Under Consideration)

The following cases are not yet definitively classified as errors but are noted for future evaluation:

### 9.1 Consistency of `intr`-Related Properties

Semantic consistency between aggregation properties (`intr`, `anded`, `ored`, `xored`) and the field declaration.

---

## Combinations Not Treated as Errors

The following combinations involve properties whose effect is nullified by other settings, but where the field itself continues to behave correctly according to its remaining properties. These are no-ops rather than silent failures, and are deliberately not classified as errors.

### `swwe`/`swwel` with `sw != rw`

`swwe`/`swwel` is a modifier that dynamically gates SW write access. Its effect is meaningful only when SW has full read/write access (`sw = rw`):

- With `sw = w`: gating the write turns the field's effective access into `na`, but the field still functions as a write-only field when the gate is open.
- With `sw = r`: there is no SW write to gate; the modifier is a no-op.
- With `sw = na`: independently rejected by Table 12.

In all of these cases, the field's primary behavior is unchanged; only the modifier is rendered ineffective. The combination is therefore allowed without error.

### `we`/`wel` with `hw not in {w, rw}`

`we`/`wel` is a modifier that dynamically gates HW write access. Its effect is meaningful only when HW has write capability:

- With `hw = r`: there is no HW write to gate; the modifier is a no-op. The field still functions as a hardware-readable field.
- With `hw = na`: there is no hardware interface to gate; the modifier is a no-op.

In both cases, the field's primary behavior is unchanged; only the modifier is rendered ineffective. The combination is therefore allowed without error.

This is the symmetric counterpart of the `swwe`/`swwel` case above.

### `errextbus` on an Internal Register

`errextbus` is meaningful only for external registers (10.6.1 h). Specifying it on an internal register has no effect on the generated register because internal registers have no external error response path. The register continues to function correctly as an internal register; only the modifier is rendered ineffective.

Flagging this as an error is the responsibility of a linter rather than the core elaborator; the elaborator simply ignores the property on an internal register.

---

## Validation Timing

All checks must run at both of the following phases, consistent with the dynamic assignment rules in Section 5.1.3.3 of the specification:

1. **At instance creation (`validate`)** - covers assignments in the definition body, instance-trailing `= value`, and default inheritance.
2. **After dynamic assignment (`revalidate`)** - covers assignments of the form `inst->prop = value`.

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
