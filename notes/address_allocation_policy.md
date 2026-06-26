# Address Allocation Policy

## Overview

This document records this implementation's policy on address allocation. Each item identifies the specification clauses that apply, the silent area where the specification does not give a direct rule, and the chosen interpretation together with its justification.

---

## 1. Explicit Address Allocation Operators

Specification 5.1.2.2 defines the scope of automatic address allocation:

> If an instance is not explicitly assigned an address allocation operator (see Table 4), the compiler assigns the address according to the alignment (see 5.1.2.2.1) and addressing mode (see 5.1.2.2.2).

When an instance *is* assigned an explicit operator (`@`, `%=`, or `+=`), the addressing-mode packing rules of automatic allocation do not apply: the elaborator does not re-impose the `compact`/`regalign`/`fullalign` logic on top of an explicit placement. The operators specify where the user wants the instance placed.

### Treatment

- `@addr`: The instance is placed at `addr`.
- `%= value`: The next address is advanced to the requested alignment boundary.
- `+= value`: The array stride is set to `value`.

### Constraints on the Operands

Bypassing the addressing-mode logic does not make the operands unconstrained. The value supplied to an operator is subject to the constraints defined elsewhere in this document:

- **Sub-word boundary** (Section 4): for the registers it covers, the resolved absolute address (`@`, or the address produced by `%=`) and the array stride (`+=`) must be a multiple of `accesswidth`. This is a condition on the final absolute address, so it applies to every operator and to automatic allocation alike.
- **Stride bounds** (Section 3): a `+=` stride must be at least the element size (to prevent overlap) and a multiple of `accesswidth` (the same sub-word requirement, applied to the spacing between array elements).

These are not "automatic-allocation rules" in the sense excluded by 5.1.2.2; they derive from requirements that hold no matter how an address was chosen.

The `regfile` `alignment` property (Appendix A) is treated differently: it constrains placement only under automatic allocation and is *not* imposed on an explicit operator's value. A user who places an instance explicitly may therefore land off the `alignment` boundary without error. Appendix B explains why this differs from the sub-word boundary.

---

## 2. Size and `accesswidth` of Instances

The addressing modes (5.1.2.2.2), the stride bounds (Section 3), and the sub-word boundary (Section 4) all rely on two per-instance quantities:

- `accesswidth` (in bytes) -- used by `compact`, which packs components tightly while keeping each aligned to the `accesswidth` parameter.
- `size` (in bytes) -- used by `regalign` (each component's start address is a multiple of its size) and `fullalign` (an array's first element aligns to the size of the whole array, rounded up to a power of two).

The specification defines these for some cases and leaves others silent. This section records the value this implementation uses for each, for a single `reg` (2.1) and `regfile` (2.2). Array-related quantities (occupancy and stride) are derived from these in Section 3.

### 2.1 `reg`

#### `accesswidth`

The `accesswidth` property of a `reg` is defined by the specification (Table 23) as the minimum software access width. The value used during automatic allocation is the property's value (in bytes, i.e., `accesswidth / 8`). No interpretation is needed.

#### `size`

The specification does not state what the "size" of a `reg` is for the purpose of 5.1.2.2.2. This implementation uses `regwidth / 8`: the storage width of the register, converted to bytes.

This is the natural reading of "size" for a `reg`: a register physically occupies `regwidth` bits, and addresses in SystemRDL are byte addresses (5.1.2.4 a). The interpretation is recorded here because the specification does not state it explicitly.

### 2.2 `regfile`

A `regfile` does not have an `accesswidth` property in the specification, and the specification does not state what its `size` is. Both must be defined by this implementation to make 5.1.2.2.2 well-defined when a `regfile` participates in automatic allocation.

#### `accesswidth`

The `accesswidth` of a `regfile` is defined as `max_internal_accesswidth`: the maximum of the `accesswidth` values of the components instantiated inside the `regfile` (i.e., the contained `reg` and `regfile` instances, the latter resolved recursively by this same rule).

The motivation is to keep each internal `reg`'s software-access boundary intact in absolute-address terms. When the `regfile` is placed at an address that is a multiple of this value, every internal `reg` placed by automatic allocation lands on an address that respects its own `accesswidth`. Taking the maximum is the smallest value that satisfies every internal `reg`'s software-access boundary simultaneously.

A `regfile` always contains at least one register or register file (per 12.2), so `max_internal_accesswidth` is always well-defined.

#### `size`

The `size` of a `regfile` is the end address of its last child (the child's offset plus its size). No rounding is applied: `size` is the address range the `regfile` actually occupies, so that a following instance can be packed immediately after it (e.g., under `compact`) with no spurious gap.

The `accesswidth`-multiple rounding that an array case needs is **not** folded into `size`. It belongs to the default array stride instead, and is described in Section 3. Keeping `size` as the unrounded occupancy gives the quantity a single, consistent meaning -- the space one instance uses -- whether or not the instance is arrayed.

**Example**

```
regfile {
    reg { regwidth = 32; } a;  // accesswidth = 32, offset 0x00, size 4
    reg { regwidth = 64; } b;  // accesswidth = 64, offset 0x08, size 8
    reg { regwidth = 32; } c;  // accesswidth = 32, offset 0x10, size 4
} rf;
```

- `accesswidth` = max(32, 64, 32) = 64 bits = 8 bytes.
- End address of last child: `c.offset + c.size` = 0x10 + 4 = 0x14 (20).
- `size` = 20. A following instance placed under `compact` starts at 0x14, with no gap.

Note that 20 is not a multiple of the `regfile`'s `accesswidth` (8). That matters only when `rf` is arrayed, where the default stride -- not `size` -- supplies the rounding (see Section 3).

### Status of These Decisions

The decisions in 2.1 and 2.2 are interpretations in silent areas of the specification:

- `reg` size: the specification does not state it; `regwidth / 8` is the natural reading.
- `regfile` `accesswidth`: not defined by the specification at all; this implementation defines it.
- `regfile` `size`: the specification does not state it; this implementation defines it as the end address of the last child, with no rounding. The `accesswidth`-multiple rounding needed for arrays lives in the default stride (Section 3), not in `size`.

Other implementations may interpret these differently. In particular, the `regfile` `accesswidth` is a strong independent interpretation by this implementation, and since `accesswidth` participates in address computation, cross-tool compatibility cannot be expected where it differs.

---

## 3. Arrays and Stride

This section defines how an array occupies address space, the stride between its elements, and the constraints that apply to a `+=` stride. It builds on the single-instance `size` and `accesswidth` of Section 2.

### 3.1 Occupancy and Default Stride

The `size` of an *arrayed* instance -- used by `fullalign` to align the first element to "the size of the whole array" -- is its occupied size:

```
occupied_size = stride * (N - 1) + size
```

where `stride` is the spacing between consecutive elements, `size` is the size of a single element (2.1 / 2.2), and `N` is the element count.

This is the address range actually spanned by the array: the last element `c[N-1]` starts at `stride * (N-1)` and occupies `size`, so the array ends at `stride * (N-1) + size`. Using `stride * N` would overcount by one trailing gap (`stride - size`) that no element occupies.

This is grounded in the specification's own numeric example. In 5.1.2.5 Example 2, `some_reg b[10] @0x100 += 0x10;` (with `regwidth = 32`, so `size = 4`, `stride = 0x10`, `N = 10`) is annotated "These consume 160-12 bytes of space." The value `160 - 12 = 148` matches `stride * (N-1) + size = 16 * 9 + 4 = 148`.

The `stride` is determined as follows:

- When the array is placed with `+=`, `stride` is the operand value, subject to the constraints of 3.2.
- Otherwise, `stride` is the **default stride**: the smallest value satisfying those same constraints. For a `reg` this is the element `size` (which already meets both); for a `regfile` it is the `size` (2.2) rounded up to a multiple of the `regfile`'s `accesswidth`, since the raw `size` may not be an `accesswidth` multiple.

When the default stride equals `size` (a `reg`, or a `regfile` whose `size` is already an `accesswidth` multiple), `occupied_size` reduces to `size * N`, matching the spec's "size of an array element multiplied by the number of elements" in 5.1.2.2.2 (c).

### 3.2 Stride Constraints

A stride -- whether supplied with `+=` or taken as the default of 3.1 -- is subject to two constraints:

1. **Lower bound: `stride >= size`.** A stride smaller than the element size causes consecutive array elements to occupy overlapping address ranges (e.g., a 4-byte `reg` with `+= 0x2` places `c[0]` at 0x0-0x3, `c[1]` at 0x2-0x5, and so on). Such a layout has no coherent hardware realization, since the same byte cannot simultaneously belong to two distinct instances; this is closer in character to the same-address restriction in 10.1 (h) than to a software-access concern. The element `size` is `regwidth / 8` for a `reg` and the `regfile`'s `size` (2.2) for a `regfile`. The elaborator rejects a too-small stride directly at the stride value, before array expansion, so the diagnostic points at the user's choice rather than at the resulting overlap. (A `+=` written on a non-array instantiation has no elements to space and is treated as a harmless no-op.)

2. **Multiple of `accesswidth`.** For the instances covered by the sub-word boundary (Section 4), the stride must be a multiple of `accesswidth`, so that every element -- not just the first -- lands on an `accesswidth` boundary. The stride determines `c[i]`'s address as `base + stride * i`; a non-multiple stride pushes later elements off the boundary even when the first element is aligned. This is also why a `regfile`'s default stride (3.1) rounds the `regfile`'s raw `size` up to an `accesswidth` multiple: for the `rf` example in 2.2 (`size = 20`, `accesswidth = 8`), a stride of 20 would put `rf[1].b` at `0x14 + 0x08 = 0x1C`, off the 8-byte boundary, whereas the rounded stride of 24 puts it at `0x18 + 0x08 = 0x20`. Folding the rounding into the stride rather than into `size` confines it to the array case, where it is actually needed.

Both constraints apply equally to a `+=` operand and to a default stride; the default stride is simply constructed to satisfy them from the outset.

### 3.3 Multiple-Dimension Arrays

For multi-dimensional arrays, this implementation treats the array as flattened into a single linear sequence. The basis is 5.1.2.2 a) 3) vi): "When using multiple-dimensions, the last subscript increments the fastest." This defines a row-major linearization (e.g., `a[2][3]` expands as `a[0][0], a[0][1], a[0][2], a[1][0], a[1][1], a[1][2]`).

The expansion *order* is stated by the specification; the rest is interpretation. Combined with 5.1.2.4 (g) ("the increment specifies the offset from one array element to the next array element"), this implementation applies the stride uniformly across every adjacent pair in the flattened sequence, including across dimension boundaries, since the specification gives no basis for treating dimension boundaries differently. Under this reading, `N` in the occupancy formula of 3.1 is the product of all dimension sizes, and the one-dimensional treatment applies unchanged.

---

## 4. Sub-Word Boundary Invariant

This invariant is not tied to a particular operator or addressing mode. It states a condition on the *final, resolved absolute address* of an instance, which must hold however that address was produced -- by automatic allocation, by `@`, or by `+=` stride. The earlier sections reference this section rather than restating it.

### 4.1 Sub-Words and the Underlying Requirement

A register with `regwidth` greater than its `accesswidth` is accessed by software in more than one piece. Such a register is divided into `regwidth / accesswidth` *sub-words*, each `accesswidth` bits wide. The specification constrains how fields may straddle these sub-words:

> 10.6.1 (f): Any field that is software-writable or clear on read shall not span multiple software accessible sub-words.

Partial reads of fields without read side-effects are explicitly permitted (10.6.1 (e)), so the requirement targets exactly fields that are software-writable or have a read side-effect (e.g., clear-on-read). For such a field, being split across two sub-words would break the atomicity of the write or the side-effect, since each software access reaches only one sub-word.

### 4.2 Why the Requirement Depends on Placement

Clause 10.6.1 (f) is written in terms of a field's bit position within its register, and is satisfied by laying fields out so that no side-effecting field crosses a sub-word boundary measured *from the register's base*. But the boundary that software actually accesses is on the *absolute* address line: a 32-bit access lands on absolute addresses 0x0, 0x4, 0x8, ... regardless of where any given register sits.

These two notions of "sub-word boundary" coincide only when the register's own base address is a multiple of `accesswidth`. Per 5.1.2.2, an instance's address is relative to its parent, and its absolute address is the sum of its own offset and the offsets of all parent objects. So a register whose intra-register field layout satisfies 10.6.1 (f) can still have its fields split by real software accesses if the register -- or any enclosing `regfile` -- is placed off an `accesswidth` boundary.

Example: a `reg` with `regwidth = 64`, `accesswidth = 32` (`size = 8`), with a writable field in bits [31:0] and another in bits [63:32]. The intra-register layout satisfies 10.6.1 (f). Placed at absolute 0x02, the register spans 0x02-0x09. A 32-bit software access at 0x04 reads absolute bytes 0x04-0x07, which straddles both fields -- exactly the atomicity break 10.6.1 (f) is meant to prevent. Placing the register at a multiple of 4 (`accesswidth / 8`) avoids this.

This is a derivation, not a verbatim rule: the specification does not state "register base addresses shall be a multiple of `accesswidth`." It is the precondition under which 10.6.1 (f)'s guarantee holds in absolute-address terms. The strength of this reasoning is discussed in 4.5.

### 4.3 The Invariant

Every `reg` and `regfile` instance shall satisfy the following (the per-case reasons, including why the rule is applied uniformly rather than only to the cases 10.6.1 (f) strictly constrains, are given in 4.4):

- The instance's resolved absolute address shall be a multiple of `accesswidth` (in bytes).
- If the instance is an array placed with `+=`, the stride shall also be a multiple of `accesswidth` (in bytes), so that every element -- not just the first -- lands on an `accesswidth` boundary (see also 3.2).

For a `reg`, the `accesswidth` is its own (2.1). For a `regfile`, the boundary requirement propagates to its base address: because the offsets of registers inside a `regfile` are relative (5.1.2.2), a misaligned `regfile` base shifts every contained register's absolute address by the same amount, breaking the requirement for any register inside it. A `regfile`'s base address (and array stride, if placed with `+=`) shall therefore be a multiple of the `regfile`'s `accesswidth` as defined in Section 2.2 -- which is the maximum of the `accesswidth` values its contents require, exactly the value needed to satisfy every internal register simultaneously.

This re-frames the Section 2.2 `regfile` `accesswidth` definition: it is not merely a value used by `compact` mode, but the boundary that an internal register's 10.6.1 (f) precondition forces onto the `regfile` as a whole.

### 4.4 Scope of Application

The invariant is applied uniformly to all `reg` and `regfile` instances, but the reasons differ by case, and recording them keeps the justification honest:

- **Split register with a side-effecting field** (`regwidth > accesswidth`, has a writable or read-side-effecting field): constrained by 10.6.1 (f) as derived above. This is the core case.
- **Non-split register** (`regwidth == accesswidth`): aligning to `accesswidth` is identical to aligning to the register's own width, which is just the default alignment of 5.1.2.2.1 ("aligned to a multiple of their width"). The invariant coincides with existing behavior; no separate justification is needed.
- **Read-only / no side-effect register**: strictly, 10.6.1 (e) permits partial reads, so such a register is *not* required by the specification to sit on an `accesswidth` boundary. This implementation nonetheless includes it in the invariant. The reason is not a specification requirement but the absence of any benefit to exempting it: the set of layouts the exemption would unlock is nearly empty (automatic allocation already aligns to width), while exempting it would require per-register access-type analysis -- complicated further by the fact that access-type and on-read properties can be set dynamically -- and would produce maps where registers of the same width sit on different boundaries depending on access type. A uniform rule is simpler for the elaborator and for downstream tools, at no real cost in expressiveness.

### 4.5 Strength of This Reasoning

The justification has two layers, and they are not equally strong:

- **Derived from the specification's invariant (moderate)**: the requirement that an instance's base address -- and, for a `regfile`, every enclosing parent's base -- be a multiple of `accesswidth`. This rests on reading 10.6.1 (f) as presupposing that the register's base sits on an `accesswidth` boundary, which the specification does not state explicitly but which is reconstructed from the fact that, without it, 10.6.1 (f) would not actually protect the field it names. The `regfile` propagation follows from this by the relative-address rule of 5.1.2.2; that step is a clean deduction, but it inherits the strength of the reconstructed premise it builds on, so the whole layer is only as strong as that reading. Both the register's own boundary and the propagation to its parent are parts of one interpretation serving 10.6.1 (f), not separately-grounded claims.
- **Design judgment, not specification (weakest)**: including read-only registers (4.4). This has no specification basis and rests purely on the cost/benefit argument given there.

The invariant is well-founded enough to be enforced as an error for the core case. It is, however, a derived interpretation, not a clause the specification states directly. A different implementation that reads 10.6.1 (f) as a pure bit-layout rule, with no implication for placement, could permit off-boundary placement without being clearly non-conformant. Users who need cross-tool portability should not rely on other tools enforcing -- or declining to enforce -- this invariant identically.

---

## Appendix A: The `alignment` Property

The `alignment` property is used in two ways. The first is defined by the specification; the second is this implementation's interpretation of a silent area.

### Used as a condition on a container's children

Per 5.1.2.2.1, `alignment` "defines the byte value of which the container's instance addresses shall be a multiple." Set on an `addrmap` or `regfile` (12.3, Table 25), it requires each child placed by automatic allocation to sit at an address that is a multiple of `alignment` (in addition to the child's own `accesswidth` boundary). This is the specification's stated meaning; no interpretation is involved.

### Used as a condition on the container's own address

The specification does not state whether `alignment` also constrains the *container's own* address. It is silent here, but the answer follows from relative addressing: a child's offset is relative to the `regfile` base (5.1.2.2), so the child's absolute address is a multiple of `alignment` only if the base is too. To make the child-level requirement hold in absolute terms, this implementation places a `regfile` carrying an `alignment` property so that its own base address is a multiple of `alignment` -- and, combined with the sub-word boundary, a multiple of `max(accesswidth, alignment)` (both being powers of two).

This propagation applies **under automatic allocation only**. When the `regfile` is placed with an explicit operator (`@`, `%=`, `+=`), the resulting address or stride is accepted even if it is not a multiple of `alignment`; see Appendix B.

## Appendix B: Sub-Word Boundary vs. `alignment`

Both the sub-word boundary (Section 4) and `alignment` propagation (Appendix A) require an instance's absolute address to be a multiple of some boundary, and both propagate to a `regfile` base through relative addressing. They are nevertheless enforced on different placement paths: the sub-word boundary on every path (automatic, `@`, `%=`, `+=`), `alignment` on automatic allocation only. The difference comes from the strength of the underlying requirement.

The sub-word boundary derives from a hardware requirement. A side-effecting field split across software-access sub-words breaks the atomicity that 10.6.1 (f) mandates; the layout has no faithful hardware realization. Because the harm is real regardless of how the address was chosen, the boundary is enforced on explicit operators too -- even though 5.1.2.2 might be read as exempting them -- since the requirement originates in 10.6.1 (f), outside the scope of that exemption.

`alignment` derives from a user preference, not a hardware requirement. A child placed off its `alignment` boundary is still fully accessible; only the user's stated preference is unmet. And `alignment` is exactly the input that 5.1.2.2 names for automatic allocation and exempts from explicit operators, so imposing it on an explicit operator would both contradict 5.1.2.2 and defeat the purpose of explicit placement (a user who writes `@0x8` has deliberately opted out). It is therefore enforced only where 5.1.2.2 calls for it, and an explicit operator may override it without error.

The propagation *reasoning* is actually firmer for `alignment` (5.1.2.2.1 speaks of addresses directly, needing no reconstruction like the 10.6.1 (f) reading of 4.5). The narrower scope reflects not weaker grounding but the benign cost of violation and the conflict with 5.1.2.2 -- a well-grounded requirement can still be the one that yields to an explicit operator.
