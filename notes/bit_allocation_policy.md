# Bit Allocation Policy

This document describes how this implementation determines the bit position of fields within a register. Two related but independent decisions are recorded here:

1. **Bit ordering mode** (`lsb0` vs `msb0`): the direction in which bits are numbered and in which width-only fields are packed.
2. **Previous-field interpretation** in implicit packing: which field counts as "the previous field" when the next field's position is determined by Section 9.2 (d)/(e).

Both decisions are points where the SystemRDL specification leaves room for interpretation, and both ultimately affect where a field is placed within a register.

---

## 1. Bit Ordering Mode

### Background

SystemRDL supports two bit ordering conventions for registers, identified by the `lsb0` and `msb0` properties (Section 9.2 of the SystemRDL 2.0 specification):

- **lsb0** (the default): bit index 0 is the least significant bit.
- **msb0**: bit index `regwidth-1` is the least significant bit.

These properties are applied at the address map level (Section 9.2 (g)) and govern two aspects of bit allocation:

1. **Automatic allocation direction** for fields declared with width only (no explicit bit range), per Section 9.2 (d) and (e).
2. **Numerical relationship in explicit ranges** of the form `[A:B]` where `A` is always the field's msb and `B` is always the field's lsb (Section 9.2, page 56), so the numerical ordering of `A` and `B` depends on the bit ordering mode.

### Specification Rules and Their Limits

The specification provides the following rules concerning bit ordering:

- Section 9.2 (c): `lsb0` is the default when no bit ordering is explicitly declared.
- Section 10.7 (a): The syntax `field_type field_instance [high:low]` (where `high > low` numerically) implies lsb0 ordering.
- Section 10.7 (b): The syntax `field_type field_instance [low:high]` (where `low < high` numerically) implies msb0 ordering.
- Section 10.7.1 (a): The `[high:low]` and `[low:high]` forms shall not be mixed in the same register.
- Section 10.7.1 (b): As long as all registers in an address map consistently use one form, no explicit `msb0` or `lsb0` property declaration is required.

These rules establish that the bit ordering can be inferred from explicit ranges, and that a register containing a mix of width-only and explicitly-positioned field declarations is permitted. However, the specification does not address the case where the first field in a register is declared with width only (`[SIZE]` form) and no explicit `msb0`/`lsb0` declaration is present in the enclosing address map. In this situation the mode cannot yet be inferred (no explicit range has been processed), and the specification does not state whether the position should be determined immediately under the default mode, or whether the determination should be deferred so that a mode inferred from a later explicit range can be applied.

### The Ambiguity Illustrated

Consider the following register definition without any explicit `msb0` or `lsb0` declaration in the enclosing address map (assume `regwidth = 32`):

```systemrdl
reg {
    field {} a[1];       // implicit position, width only
    field {} b[1:2];     // explicit range, [low:high] form (1 < 2)
} my_reg;
```

The question this example raises is: **what is the position of field `a`?**

At the point where `a` is encountered in the source, the following are simultaneously true:

- No explicit `msb0` or `lsb0` declaration has been made.
- No explicit range has been encountered that would imply a particular mode.
- The default mode is `lsb0` per Section 9.2 (c), but the specification does not state at what point this default is committed to.
- A subsequent field `b[1:2]` will imply msb0 ordering once it is processed.

Two outcomes for `a`'s position can be defended on the basis of the specification text. In both cases, `b` occupies bits 1 and 2 of the register; the question is solely about where `a` is positioned.

#### Outcome 1: `a` at bit `[0:0]`

If the default `lsb0` mode is taken to apply immediately at the point of processing `a`, then `a` is allocated according to lsb0 packing rules, starting at bit 0. Under this view, `a` occupies bit `[0:0]`, and `b` occupies bits 1 and 2 next to it.

#### Outcome 2: `a` at bit `[31:31]`

If the mode for the register is determined after considering all explicit ranges within the register (per Section 10.7.1 (b), which allows the mode to be inferred from consistent use within an address map), then `b[1:2]` causes the register to be treated as msb0. Under this view, `a` is allocated according to msb0 packing rules, starting at bit `regwidth-1 = 31`. The position of `a` is `[31:31]`, and `b` occupies bits 1 and 2.

Whether the mode determination is performed eagerly (during the processing of `a`, defaulting to lsb0) or lazily (deferred until enough information is available, allowing inference from `b`) is itself a question the specification does not address. The two outcomes correspond to two different commitments to when and how the mode is fixed.

#### Why Each Outcome Can Be Defended

The specification does not state whether, when a width-only field needs to be positioned before any explicit range has been processed, the default `lsb0` mode should be committed immediately to determine the position, or whether mode determination should be deferred until an explicit range provides enough information to infer the mode. The two outcomes above correspond to two different answers to this single question. Because the specification is silent on this point, different implementations can arrive at different positions for `a` while each remaining defensible on the basis of partial readings of the specification text.

### Decision: No Mode Inference

This implementation **does not infer the bit ordering mode from explicit bit ranges**. The mode is determined solely by explicit `msb0` or `lsb0` declaration, with `lsb0` as the default when no declaration is present. The default is committed to at the start of processing each address map, before any fields are allocated.

The rationale for this decision is:

1. **Specification ambiguity**: As described in the previous section, the specification leaves multiple questions about the interaction between the default mode, mode inference, and the order of evaluation entirely unanswered. Implementing inference requires the tool to make several implementation-specific decisions that the specification does not endorse, and the same source file could plausibly receive different valid interpretations across tools.

2. **Implementation simplicity**: Inference requires either a multi-pass evaluation strategy or a forward-looking analysis to determine the mode before allocating implicit fields. A single-pass evaluation with explicit mode declaration is significantly simpler and easier to verify.

3. **Sufficient expressiveness**: A user who intends to use msb0 ordering can declare `msb0;` explicitly in the enclosing address map. This is a minor addition that resolves all ambiguity at the source.

4. **Predictable behavior**: With explicit declaration, the bit ordering mode is determined locally and unambiguously. Users do not need to reason about how the tool might interpret a mixture of implicit and explicit field declarations.

The mode is therefore determined as follows:

1. If `msb0` is declared in the enclosing address map, msb0 mode is used.
2. If `lsb0` is declared in the enclosing address map, lsb0 mode is used.
3. If neither is declared, the default `lsb0` mode is used.

### Divergence from Other Tools

Other SystemRDL processing tools may choose a different interpretation. In particular, tools that follow Section 10.7.1 (b) closely may infer the mode from explicit ranges and accept the example above without requiring an `msb0` declaration.

This implementation's choice not to infer the mode is a deliberate decision made in the face of specification ambiguity. SystemRDL source files that rely on mode inference (i.e., that omit `msb0` declarations while using `[low:high]` ranges) will be rejected by this implementation and must be modified to either:

- Add an explicit `msb0;` declaration to the enclosing address map, or
- Convert the ranges to `[high:low]` form (which implies lsb0).

Both modifications are minor and preserve the original intent of the register layout.

### Summary

| Aspect | This Implementation |
| --- | --- |
| Default mode | `lsb0` |
| Mode determination | Explicit declaration only |
| Mode inference from ranges | Not supported |
| Mixed implicit/explicit fields | Handled in the explicitly declared (or default) mode |
| `[low:high]` range without `msb0` declaration | Error |
| `[high:low]` range without `lsb0` declaration | Accepted (default lsb0) |

---

## 2. Previous-Field Interpretation in Implicit Packing

### Background

Section 9.2 (d) (and the symmetric (e) for msb0) describes how a field declared with width only is positioned within a register:

> In the default mode lsb0, unless bit allocation is explicitly defined, fields shall be positioned sequentially in the order they are instantiated in a register, starting at bit 0 with no padding between fields. (Each subsequent field's least significant bit (LSB) shall be made equal to one (1) greater than the most significant bit (MSB) of the previous field.)

The packing rule relies on a notion of "the previous field". The specification does not explicitly define what counts as the previous field, beyond the phrase "the order they are instantiated".

Separately, Section 10.1 (d) permits two field instances to occupy overlapping bit positions within a register if one field is read-only and the other is write-only:

> Two field instances shall not occupy overlapping bit positions within a register unless one field is read-only and the other field is write-only.

How these two rules interact when implicit (width-only) packing is used with a mix of read-only and write-only fields is not directly addressed by the specification.

### The Ambiguity

Consider:

```systemrdl
reg {
    field {sw=w; hw=r;} in[8];     // write-only
    field {sw=r; hw=w;} out[8];    // read-only
} fifo_data;
```

"The previous field" for `out` admits two distinct readings:

- **Interpretation (i)**: the field immediately preceding `out` in instantiation order, regardless of access attributes. The previous field is `in`. `out` is placed starting at bit 8 (just above `in`'s MSB), so `in` occupies bits `[7:0]` and `out` occupies bits `[15:8]`.

- **Interpretation (ii)**: the previous field of the same access category. The previous read-only field before `out` is none, so `out` starts at bit 0. Combined with `in` occupying bits `[7:0]` as a write-only field starting at bit 0, this places `in` and `out` at the same bit range `[7:0]`, which is permitted by Section 10.1 (d).

Both interpretations can be argued from the specification text. The phrase "the previous field" is not defined in a way that resolves which reading is intended, and Section 10.1 (d) does not state how its exception is to be reached through implicit packing.

#### Why Each Interpretation Is Defensible

- **(i)** aligns with the natural reading of "the order they are instantiated" in Section 9.2 (c)(d)(e), which describes a single sequence across all fields. It also aligns with "no padding between fields", which suggests a single sequential placement. These phrases admit being read across all fields without splitting by access category, and that is the most direct reading.

- **(ii)** is not contradicted by the specification text. "The previous field" is not defined explicitly, and Section 10.1 (d) provides for overlapping placements of read-only and write-only fields. A reading in which the packing rule is applied per access category, allowing the exception of Section 10.1 (d) to be reached naturally through width-only declarations, is consistent with both rules taken individually. This interpretation is also supported by the typical hardware design pattern of overlapping write-only input ports and read-only output ports for FIFO-like registers (see below).

The specification does not adjudicate between these two readings.

### Decision: Interpretation (i)

This implementation adopts **interpretation (i)**: the previous field is the field immediately preceding the current one in instantiation order, regardless of access attributes.

The reason for this choice is that interpretation (i) follows directly from the natural reading of Section 9.2 (c)(d)(e), without requiring the specification text to be construed beyond what it says. Interpretation (ii) requires reading "the previous field" as implicitly partitioned by access category, which the specification does not state. Choosing (i) keeps the implementation aligned with the most direct reading and avoids importing an additional interpretive layer.

This is a reason for choosing (i), not a positive argument that (ii) is wrong. The text of Section 9.2 (c)(d)(e) and Section 10.1 (d) admits interpretation (ii) as well; the choice is which reading to commit to in the face of silence, and the more direct reading is preferred here.

### Consequence: FIFO-Style Registers Require Explicit Bit Ranges

A common hardware design pattern is a FIFO-style register in which the same address serves as both a write-only input port and a read-only output port, with both ports occupying the same bit range. Under interpretation (i), the natural-looking declaration

```systemrdl
reg fifo_data {
    field {sw=w; hw=r;} in[8];
    field {sw=r; hw=w;} out[8];
};
```

does not produce an overlap. `in` occupies bits `[7:0]` and `out` occupies bits `[15:8]`, with `out` placed above `in`. This does not match the typical designer intent for such a register.

To express the intended overlapping placement, the user must use explicit bit ranges:

```systemrdl
reg fifo_data {
    field {sw=w; hw=r;} in[7:0];
    field {sw=r; hw=w;} out[7:0];
};
```

The Section 10.1 (d) exception for read-only/write-only overlap is reached through explicit positioning rather than through implicit packing. This is a slight inconvenience compared to the width-only form, but it makes the overlap intent explicit at the source, which has its own value: the reader of the register definition can see the overlap directly rather than having to derive it from access-attribute-dependent packing rules.

### Summary

| Aspect | This Implementation |
| --- | --- |
| "Previous field" definition | The field immediately preceding in instantiation order |
| Access-category-based partitioning | Not applied |
| Implicit overlap of read-only and write-only | Not produced; fields are placed sequentially |
| Reaching the 10.1 (d) overlap exception | Requires explicit bit ranges |

---

## Overall Note

The two policies above address independent aspects of bit allocation but share a common shape: each takes a position in the face of specification silence, and each does so by choosing the reading closest to the specification text. Where the specification text equally permits multiple readings, this implementation prefers the more direct one and asks users to be explicit when they need a different behavior.
