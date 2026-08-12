# Observations

This document records observations about the SystemRDL specification that are
noticed during implementation but are **not** acted on. Unlike the other files
under `notes/`, which record deliberate implementation policies, entries here
are context that may become useful later -- for example, when the
specification is updated, when a discussion arises upstream, or when this
implementation's scope expands.

Each entry describes what was observed, why it looks noteworthy, and why no
implementation change was made.

---

## 1. Asymmetry between `we` / `wel` and `hwenable` / `hwmask` type declarations

### Observation

In Table 18 (Hardware access properties), `we` and `wel` accept
`boolean or reference`, while `hwenable` and `hwmask` accept `reference` only.

The generally applicable meaning of the boolean form for hardware-facing
properties -- as seen in `we`, `wel`, `hwclr`, `hwset`, `swwe`, `swwel` --
is "generate a dedicated port and expose it on the hardware interface." Under
that reading, `hwenable = true;` would naturally mean "generate a
`fieldwidth`-bit update-mask port," symmetric with `we = true;` generating a
1-bit write-enable port. Nothing in the semantics of `hwenable` / `hwmask`
seems to preclude such a boolean form.

### Why It Looks Noteworthy

The type declaration in Table 18 appears to break an otherwise consistent
pattern across the hardware-access property family. It is not obvious from
the specification whether this is deliberate or a specification oversight.

A widely used existing implementation, `systemrdl-compiler`, follows Table 18
strictly and rejects boolean assignments to `hwenable` / `hwmask`, so the
asymmetry propagates to at least one existing consumer of the specification.

### Why No Implementation Change

Users who want the "generate a port" behavior can already achieve it by
declaring a `signal` explicitly and assigning it as the reference. There is
no capability that is impossible to express under the current type
declaration, only a small ergonomic difference. Given no functional harm and
the desire to stay close to the specification's explicit type declarations,
this implementation follows Table 18 as written.

The observation is recorded here so that, should the specification be
revisited upstream or should an issue be raised for clarification, the
reasoning is available.

---

## 2. Automatic field placement can cross an accesswidth sub-word boundary

### Observation

Section 9.2 (d)/(e) specifies that width-only fields are packed sequentially
with no padding between them (each field's LSB is one greater than the
previous field's MSB, in lsb0 mode). When a register has `regwidth` greater
than `accesswidth`, this packing can place a single field so that it straddles
an accesswidth sub-word boundary.

For example, with `regwidth = 64` and `accesswidth = 32`:

```systemrdl
reg {
    regwidth = 64;
    accesswidth = 32;
    field { sw = rw; hw = r; } a[31];
    field { sw = rw; hw = r; } b[2];
} a;
```

Field `a` occupies bits `[30:0]`, and the next width-only field `b` is placed
immediately above it at bits `[32:31]`. That range crosses the sub-word
boundary between the lower access word (bits `[31:0]`) and the upper access
word (bits `[63:32]`): `b` cannot be read or written in a single `accesswidth`
access, and this implementation rejects it as an error.

### Why It Looks Noteworthy

A designer using width-only fields for convenience generally expects the tool
to lay fields out sensibly, and a field that silently straddles an access
boundary is easy to overlook and awkward to access in hardware. Because the
specification also defines `accesswidth`, one might expect automatic placement
to take it into account and avoid such straddling. It does not: the packing
rule is defined purely in terms of sequential bit positions, independent of
`accesswidth`. In this sense the no-padding rule reduces the usefulness of
automatic placement for registers wider than their access width.

### Why No Implementation Change

Section 9.2 (d)/(e) explicitly requires "no padding between fields." Inserting
padding to avoid a sub-word boundary crossing would directly violate that
rule.

A designer who needs a field to stay within an access word can express that
directly with an explicit bit range (for example, placing `b` at `[33:32]`),
which makes the intent visible at the source. This implementation therefore
follows the specification and packs width-only fields with no padding; when
the sequential layout leads a field across a sub-word boundary, it is reported
as an error rather than silently accepted or worked around.

The observation is recorded here because the inconvenience originates in the
specification itself: conforming to the no-padding rule is what can lead
automatic placement to produce a boundary-crossing field in the first place.
Bit placement is fundamental to SystemRDL and is the front-end's
responsibility. It is therefore recorded here as feedback toward the
specification: automatic placement and the `accesswidth` sub-word boundary are
in tension under the current no-padding rule, and the specification should be
updated to have automatic placement take `accesswidth` into account so that
this tension is resolved.
