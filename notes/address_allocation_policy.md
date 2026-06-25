# Address Allocation Policy

## Overview

This document records this implementation's policy on address allocation. Each item identifies the specification clauses that apply, the silent area where the specification does not give a direct rule, and the chosen interpretation together with its justification.

---

## 1. Explicit Address Allocation Operators

Specification 5.1.2.2 defines the scope of automatic address allocation:

> If an instance is not explicitly assigned an address allocation operator (see Table 4), the compiler assigns the address according to the alignment (see 5.1.2.2.1) and addressing mode (see 5.1.2.2.2).

The implication, read straightforwardly, is that when an instance *is* assigned an explicit operator (`@`, `%=`, or `+=`), the alignment and addressing-mode rules of automatic allocation do not constrain it. This implementation takes that reading at face value: explicit operators specify where the user wants the instance placed, and the elaborator accepts the placement as given.

### Treatment

- `@addr`: The instance is placed at `addr`. No alignment or addressing-mode check is applied at this layer.
- `%= value`: The next address is advanced to the requested alignment boundary. No further check from automatic-allocation rules is applied.
- `+= value`: The array stride is set to `value`. The stride is not required to be a multiple of any alignment derived elsewhere; see the exception below.

### Exception: Lower Bound on `+=` Stride

A stride smaller than the element size causes consecutive array elements to occupy overlapping address ranges (e.g., a 4-byte `reg` with `+= 0x2` places `c[0]` at 0x0-0x3, `c[1]` at 0x2-0x5, and so on). Such a layout has no coherent hardware realization, since the same byte cannot simultaneously belong to two distinct register instances. The same problem arises for a `regfile` array whose stride is smaller than the size of one `regfile`.

This is closer in character to the same-address restriction in 10.1 (h) than to a software-access concern: it is a structural impossibility, not a question of whether software can reach the layout. The elaborator therefore rejects this case directly at the stride value, before array expansion, so that the diagnostic points at the user's choice rather than at the resulting overlap.

**Constraint**: A `+=` stride value must be greater than or equal to the element size in bytes. For a `reg`, the element size is `regwidth / 8`; for a `regfile`, it is its total size (see Section 2.3).

This rule is also recorded in [implicit_constraints.md, Section 9](implicit_constraints.md).

### Note on Downstream Acceptance

The elaborator's acceptance of an explicit placement does not guarantee that the layout is realizable by downstream tools. A placement that satisfies the structural rule above may still be rejected by a backend (such as an RTL generator) when the resulting addresses do not meet that backend's bus-width, software-access, or device-specific requirements. Users who place instances explicitly should ensure their layout is compatible with the intended downstream flow.

---

## 2. Automatic Address Allocation

When an instance is not placed by an explicit operator, the elaborator computes its address according to the addressing mode and the relevant property of the instance. This section records what those properties mean for `reg` and `regfile`, including the interpretations this implementation makes where the specification is silent.

### 2.1 What Each Addressing Mode Requires

Specification 5.1.2.2.2 defines three addressing modes:

- **compact**: "Specifies the components are packed tightly together while still being aligned to the `accesswidth` parameter."
- **regalign**: "Specifies the components are packed so each component's start address is a multiple of its size (in bytes)."
- **fullalign**: For arrays, the first element aligns to the size of the whole array (rounded up to a power of two); otherwise behaves like `regalign`.

Two pieces of per-instance information are needed:

- `accesswidth` (in bytes) -- used by `compact`.
- `size` (in bytes) -- used by `regalign` and `fullalign`.

The remainder of this section gives the values this implementation uses for each, for both `reg` and `regfile`.

### 2.2 `reg`

#### `accesswidth`

The `accesswidth` property of a `reg` is defined by the specification (Table 23) as the minimum software access width. The value used during automatic allocation is the property's value (in bytes, i.e., `accesswidth / 8`). No interpretation is needed.

#### `size`

The specification does not state what the "size" of a `reg` is for the purpose of 5.1.2.2.2. This implementation uses `regwidth / 8`: the storage width of the register, converted to bytes.

This is the natural reading of "size" for a `reg`: a register physically occupies `regwidth` bits, and addresses in SystemRDL are byte addresses (5.1.2.4 a). The interpretation is recorded here because the specification does not state it explicitly.

### 2.3 `regfile`

A `regfile` does not have an `accesswidth` property in the specification, and the specification does not state what its `size` is. Both must be defined by this implementation to make 5.1.2.2.2 well-defined when a `regfile` participates in automatic allocation.

#### `accesswidth`

The `accesswidth` of a `regfile` is defined as:

- `max(alignment_value, max_internal_accesswidth)`, where `alignment_value` is the `alignment` property of the `regfile` if explicitly set, and `max_internal_accesswidth` is the maximum of the `accesswidth` values of the components instantiated inside the `regfile` (i.e., the contained `reg` and `regfile` instances, the latter resolved recursively by this same rule).
- If `alignment` is not explicitly set, the value is simply `max_internal_accesswidth`.

The motivation is to keep each internal `reg`'s software-access boundary intact in absolute-address terms. When the `regfile` is placed under `compact` mode at an address that is a multiple of this value, every internal `reg` placed by automatic allocation lands on an address that respects its own `accesswidth`. Taking the maximum across the explicit `alignment` and the internal `accesswidth` values is the smallest value that simultaneously satisfies the user's explicit alignment request (if any) and every internal `reg`'s software-access boundary.

If the user sets `alignment` to a value smaller than `max_internal_accesswidth`, the internal value still governs: an explicit `alignment` cannot relax the boundary required by the internal contents, because doing so would break the internal `reg`'s addressing in the array case.

If the user sets `alignment` to a value larger than `max_internal_accesswidth`, the explicit value governs: the user is asking for a stricter boundary than the contents require, and that request is honored.

A `regfile` always contains at least one register or register file (per 12.2), so `max_internal_accesswidth` is always well-defined.

#### `size`

The `size` of a `regfile` is the end address of its last child (the child's offset plus its size) rounded up to a multiple of the `regfile`'s `accesswidth` (defined above).

Rounding up to the `accesswidth` is needed for the array case: when a `regfile` array uses `size` as its stride (e.g., under `regalign`), the stride must be a multiple of `accesswidth` so that the same software-access boundary holds at every array element. Without the rounding, an internal `reg` in `rf[1]`, `rf[2]`, ... could land on an address that violates its own `accesswidth`.

**Example (last child already aligned)**

```
regfile {
    reg { regwidth = 32; } a;  // accesswidth = 32, offset 0x00, size 4
    reg { regwidth = 64; } b;  // accesswidth = 64, offset 0x08, size 8
} rf;
```

- `accesswidth` = max(32, 64) = 64 bits = 8 bytes.
- End address of last child: `b.offset + b.size` = 0x08 + 8 = 0x10 (16).
- 16 is already a multiple of 8, so no rounding is needed.
- `size` = 16.

In an array `rf[N]`, the stride is 16, and each `rf[i].b` lands at `0x10 * i + 0x08`, which is an 8-byte boundary as required.

**Example (last child not aligned, rounding applies)**

```
regfile {
    reg { regwidth = 32; } a;  // accesswidth = 32, offset 0x00, size 4
    reg { regwidth = 64; } b;  // accesswidth = 64, offset 0x08, size 8
    reg { regwidth = 32; } c;  // accesswidth = 32, offset 0x10, size 4
} rf;
```

- `accesswidth` = max(32, 64, 32) = 64 bits = 8 bytes.
- End address of last child: `c.offset + c.size` = 0x10 + 4 = 0x14 (20).
- 20 is not a multiple of 8; rounded up to the next multiple of 8, this becomes 24 (0x18).
- `size` = 24.

In an array `rf[N]`, the stride is 24. If `size` were the unrounded 20 instead, `rf[1].b` would land at `0x14 + 0x08` = 0x1C, which is not an 8-byte boundary and would violate `b`'s `accesswidth`. The rounding ensures `rf[1].b` lands at `0x18 + 0x08` = 0x20, an 8-byte boundary.

### Status of These Decisions

The decisions in 2.2 and 2.3 are interpretations in silent areas of the specification:

- `reg` size: the specification does not state it; `regwidth / 8` is the natural reading.
- `regfile` `accesswidth`: not defined by the specification at all; this implementation defines it.
- `regfile` `size`: the specification does not state it; this implementation defines it as the end address of the last child rounded up to a multiple of `accesswidth`.

Other implementations may interpret these differently, particularly the `regfile` `accesswidth`. Users who need cross-tool portability should place instances with explicit `@`, `%=`, or `+=` operators, since these are specification-defined and bypass automatic allocation entirely.
