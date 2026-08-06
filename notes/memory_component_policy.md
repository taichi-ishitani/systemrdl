# Memory Component Modeling Policy

## Overview

The SystemRDL 2.0 specification (Clause 11) defines the memory (`mem`) component only loosely. It states that a memory is an array of `mementries` entries, each `memwidth` bits wide, that a memory is always external, and that its children are virtual instances. It does not specify how a memory occupies byte-address space, how `memwidth` relates to the addresses assigned to virtual registers, how `accesswidth` is determined, or how `memwidth` defaults when the entry contents vary. This document records the model this implementation adopts for those points.

Several of the decisions below are independent interpretations in areas where the specification is silent. Where a decision derives from spec text it is noted; otherwise it is this implementation's own modeling choice, made for internal consistency and for reuse of the existing register allocation logic. Other tools may model memories differently, and cross-tool compatibility cannot be assumed for the memory-specific quantities defined here.

---

## 1. Two Regions: One for Virtual Registers, One for Fields

The specification gives two width-like quantities, `memwidth` and `mementries`, and a rule (11.2 (i)) that virtual registers must fit within the memory's address space. This implementation reads the geometry as two distinct regions:

- **`memwidth` (rounded up to a power-of-two number of bytes) * `mementries`** determines the region in which **virtual registers** may be instantiated -- the memory's total address-space occupancy.
- **`memwidth`** determines the region in which **fields** may be instantiated *within* a virtual register.

The first is the address-direction extent (how far virtual registers may be placed); the second is the width-direction extent (how wide the fields inside any one virtual register may reach). They are independent axes, and the constraints on each are described separately below.

---

## 2. Total Size and the Virtual-Register Region

Because SystemRDL addresses are byte addresses (11.2 (b)), a memory occupies whole bytes. Per 11.2 (e), the virtual register width is "the minimum power of two bytes which can contain the memory width." This implementation uses that rounded width as the per-entry address extent:

- **Entry address width** = `memwidth` rounded up to the minimum power-of-two number of bytes that contains it.
- **Total size** = `mementries` * (entry address width), in bytes. This is the `size` exposed for the memory, consistent with `size` on every other component meaning byte occupancy in the address map.

The total size defines the region within which virtual registers may be instantiated. It is fixed by `memwidth` and `mementries` -- it is *not* derived from the virtual registers that happen to be present. Virtual registers are then placed within this fixed region and must fit inside it (Section 3).

---

## 3. Placement of Virtual Registers

To software, a virtual register is accessed exactly like an ordinary register. This implementation therefore places virtual registers the same way ordinary registers are placed inside an `addrmap` / `regfile`: address allocation and size computation follow the ordinary register rules.

- Virtual registers are assigned addresses within the memory's address space using the same allocation as registers in an address map (following the enclosing `addressing` mode and applicable `alignment`).
- Virtual registers do not overlap (11.2 (j)).
- The address space occupied by the placed virtual registers shall be less than or equal to the memory's total size (11.2 (i)). If the occupied space exceeds the total size, it is an error.

The memory's total size (Section 2) is the fixed upper bound; the virtual registers' occupancy is what is actually used. The latter must not exceed the former.

### Virtual register width vs. `memwidth`

Per 11.2 (e), a virtual register's width is "limited to the minimum power of two bytes which can contain the memory width." This implementation reads "limited to" as an upper bound on the virtual register's own `regwidth`: a virtual register's width (its `regwidth`, in bytes) shall not exceed the minimum power-of-two bytes containing `memwidth`. A virtual register wider than that is an error.

This check prevents a geometric inconsistency at its source. For example, with `memwidth = 8` and `mementries = 1`, the total size is 1 byte (8 bits rounds to 1 byte). A virtual register with `regwidth = 64` would occupy 8 bytes -- larger than the memory it lives in. The width check (11.2 (e)) rejects it directly, with the actual cause: the virtual register is wider than `memwidth` permits.

---

## 4. Field Region: Bounded by `memwidth`

Per 11.2 (e), all virtual fields shall fit within `memwidth`. Within a virtual register, fields may be instantiated only up to `memwidth` bits; the field-instantiation region is `memwidth`, not the rounded entry width.

When `memwidth` is not itself a power-of-two number of bytes (e.g. `memwidth = 12`), the entry address width (Section 2) exceeds `memwidth` (12 bits occupies 2 bytes). The bits between `memwidth` and the rounded width lie outside the field-instantiation region: no field may be placed there (11.2 (e)).

### Two widths are exposed

Because the logical field region and the address-map entry width diverge when `memwidth` is not a power-of-two byte count, both are made available:

- `memwidth` -- the logical entry bit width; the region within which fields must fit.
- `size` -- the address-map occupancy in bytes (rounded entry width times `mementries`).

`size` is the address-basis quantity, matching every other component. A logical total (`memwidth` * `mementries`) is not exposed as a separate accessor: it is derivable from `memwidth` and `mementries`, and no current use requires it, consistent with the general policy of not adding speculative accessors.

---

## 5. `memwidth` Default

Per 11.3.1 (d), `memwidth` defaults to `regwidth`. That default names `regwidth` as its source, so it applies only where a `regwidth` is available to name -- that is, where virtual registers are present. This implementation resolves the default as follows:

- **`memwidth` specified explicitly** -- the given value is used, regardless of the virtual registers present. The virtual registers must then be consistent with it (Sections 3 and 4).
- **`memwidth` omitted, virtual registers present** -- the default is `max(regwidth)` over the instantiated virtual registers. The maximum is used because `memwidth` must contain every virtual register's fields (Section 4).
- **`memwidth` omitted, no virtual registers** -- an error. With no virtual register present, the `regwidth` that the default names does not exist, so `memwidth` cannot be defaulted and must be specified explicitly.

---

## 6. `accesswidth`

A memory does not have an `accesswidth` property (Clause 11, Table 24), but a value is required: a memory is instantiated as a child of an `addrmap` / `regfile`, and its placement (the sub-word boundary invariant, and the parent's own `accesswidth` computation) needs it. It is determined depending on whether virtual registers are present.

- **Virtual registers present.** `accesswidth` is the maximum of the `accesswidth` values of the contained virtual registers (`max_internal_accesswidth`), the same rule as for a `regfile` / `addrmap`. This is the value exposed.

  Using `memwidth` here would be wrong. `memwidth` is the full entry width, analogous to a register's `regwidth`, not a single access unit; a virtual register whose `regwidth` exceeds its `accesswidth` is itself reached over more than one access. Just as a register distinguishes `regwidth` (the whole) from `accesswidth` (one access), a memory distinguishes `memwidth` from `accesswidth`, and the correct exposed value is the maximum access width of the contents.

- **No virtual registers.** With no contents, `max_internal_accesswidth` is undefined, but an `accesswidth` is still needed for the memory's own placement. In this case it is the entry address width (Section 2): `memwidth` rounded up to the minimum power-of-two bytes.

---

## 7. External, and Virtual-Instance Property Rules

### Always external

Per 11.2 (a), every memory instance has an external instance type; a memory cannot be internal.

### `sw` -- same as the parent memory

Per 11.2 (f), virtual registers, register files, and fields shall have the same `sw` (software access) as the parent memory. This implementation verifies the match on the memory side: the memory checks that the `sw` of its virtual contents agrees with its own `sw`, and a disagreement is an error. Locating the check on the memory keeps this memory-specific rule within the memory rather than adding a "parent is a memory" branch to ordinary field evaluation.

### Hardware properties -- validated, not exposed

Per 11.2 (g), hardware properties on virtual registers and fields are "ignored." This implementation reads "ignored" as *not reflected in the memory's address-map (software) view*, not as *unchecked*. The virtual instances are virtual only in how they appear in the memory's address map; the underlying hardware is still implemented as described. Hardware properties therefore continue to govern that physical implementation, and their validity is checked exactly as for an ordinary register or field -- individual values, combinations among hardware properties, and combinations of hardware and software properties are all validated, and a contradictory hardware description is an error. What "ignored" removes is only the *effect* on the address-map representation: hardware behaviour is not surfaced in the memory's software view. Validation is retained; the address-map effect is dropped.

### Virtual fields -- `sw` only among software properties

Per 11.2 (h), a virtual field cannot carry software properties other than `sw`. The software-side properties permitted on an ordinary field (`rclr`, `rset`, `woset`, `woclr`, `onread`, `onwrite`, `swwe`, `swwel`, `swmod`, `swacc`, `singlepulse`, and so on) are not permitted on a virtual field; their presence is an error. Only `sw` is allowed.

### Distinction between "ignored" and "not allowed"

The three property rules differ in how a stray property is treated, driven by the specification's wording:

- `sw` (11.2 (f), "shall have the same") -- must match the parent; a mismatch is an error.
- Hardware properties (11.2 (g), "ignored") -- validated as usual (they describe the real implementation), but not surfaced in the address-map view; never an error merely for being present.
- Non-`sw` software properties (11.2 (h), "cannot have") -- not allowed on a virtual field; their presence is an error.

---

The status of these decisions: the property rules of Section 7 are grounded in explicit spec text (11.2 (a), (e)-(h)). The two-region geometry (Section 1), the total-size definition (Section 2), the placement-by-ordinary-register-rules and the width bound (Section 3), the `memwidth`-bounded field region (Section 4), the `memwidth` default including the error case (Section 5), and the `accesswidth` determination (Section 6) are independent interpretations in areas where the specification is silent, recorded here so the reasoning behind them is available if questioned.
