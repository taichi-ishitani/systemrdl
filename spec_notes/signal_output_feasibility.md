# Signal Output Feasibility

This document analyzes whether SystemRDL's `signal` component can be used as an external output port. The conclusion is that it cannot be used as an output in any practically useful sense, despite the specification's introductory wording suggesting both input and output roles.

## Background

The SystemRDL 2.0 specification, clause 8.1, introduces `signal` with the following wording:

> A signal is a non-structural component used to define and instantiate wires (as additional inputs and/or outputs). Signals create named external ports on an implementation and can connect certain internal component design properties to the external world.

On its face, this admits both input and output use. The remainder of clause 8, however, only develops the input case. The signal properties listed in Table 10 (`signalwidth`, `sync`, `async`, `cpuif_reset`, `field_reset`, `activelow`, `activehigh`) cover declarative attributes of the wire itself (width, clocking, special reset roles, polarity); none of them describes how the signal's value is driven. The chapter that follows, 17.1, treats signals exclusively in the context of reset distribution.

The question this document addresses is whether, beyond the specification's introductory phrase, signals are actually usable as outputs in the standard SystemRDL language.

## Standard Language: Not Usable as an Output

In the standard SystemRDL vocabulary and grammar, a signal cannot serve as an external output. Two independent reasons converge on this conclusion.

### No `next`-Equivalent Property

A field can be driven from a referenced source by assigning the `next` property. This is the only standard mechanism by which the value of one component can be sourced from another within a SystemRDL description: assign a reference to a property of `reference` type, and the generator wires the referenced source to the receiving component.

`signal` has no analogous property. Table 10 lists only declarative attributes; there is no signal-side property whose role is "the source that drives this signal". Without such a property, a signal has no slot to receive a driving source in the standard vocabulary.

### Grammar Has No Instance-to-Instance Connection

Annex B.10 defines property assignments as follows (simplified):

```
explicit_prop_assignment ::= prop_assignment_lhs [ = prop_assignment_rhs ]
post_prop_assignment    ::= prop_ref [ = prop_assignment_rhs ] ;
prop_ref                ::= instance_ref -> prop_keyword
                          | instance_ref -> id
```

The left-hand side of an assignment is always a property -- either the property of an instance (`inst -> prop`) or the property of the current scope. There is no production that puts a bare instance reference (an `instance_ref` without a following `->`) on the left-hand side.

Consequently, expressions of the form `signal_inst = some_field->intr;` are simply not in the grammar. SystemRDL provides no syntactic form for "connect this instance to that one" as a direct statement; values always flow through reference-typed properties, with the receiving side being a property and the source being an instance reference.

## With a User-Defined Property: Technically Possible, Practically Useless

A user-defined property (UDP) can extend `signal` with a `reference`-typed property that names a driving source:

```
property drive_source {
    component = signal;
    type = ref;
};

addrmap foo {
    reg { field { ... } intr; } intr_reg;
    signal { ... } chip_intr_out;
    chip_intr_out->drive_source = intr_reg.intr->intr;
};
```

This is syntactically legal: UDPs can be attached to any component, including signals, and a `reference`-typed UDP can carry a reference. A generator that recognizes this UDP could, in principle, expose `chip_intr_out` as an output port driven by the referenced source.

The fatal limitation is the `reference` type itself. A reference holds one reference -- a single field, signal, or property output. It cannot hold the result of an operation. Assignments like

```
chip_intr_out->drive_source = intr_reg_a.intr->intr | intr_reg_b.intr->intr;  // not allowed
chip_intr_out->drive_source = ~field_a;                                       // not allowed
```

are rejected by the type system: `|` and `~` produce values, not references, and a reference-typed location cannot hold a value. The standard SystemRDL type system has no construct that lets an operation result participate in a connection.

This restricts the UDP-based approach to one-to-one connections: a signal can only be driven by exactly one referenceable thing. The practically useful cases for an output signal -- ORing several interrupt sources into a chip-level pin, inverting or gating a value before exposing it externally, combining bits from multiple fields -- are all forms of "combine or transform, then emit", and none of them is expressible.

For one-to-one connections that the UDP approach does support, the same effect is already available through the existing automatic ports: a register containing an `intr` field already produces the same one-bit OR output as a port, and that port is referenceable from the SystemRDL description by name. Routing it externally through an additional signal adds an extra named hop without changing the resulting hardware. The naming flexibility this offers is marginal at best.

## Conclusion

The output use of `signal` is not realizable in the standard SystemRDL language and gains essentially nothing from a UDP-based extension:

- In the standard language, there is no property to receive a driving source on the signal side, and no grammar production to connect instances directly.
- With a UDP, the connection can be expressed, but the `reference` type restricts it to one-to-one. Aggregation and value transformation -- the operations that would make output signals useful -- remain inexpressible.
- One-to-one connections, the only case the UDP approach handles, duplicate the existing automatic ports without adding capability.

The introductory phrase in 8.1 ("inputs and/or outputs") is formally inclusive but is not backed by the rest of the language. In practice, `signal` is an input-only mechanism, used to name reset signals and external control inputs to fields. Generators are not expected to provide an "output signal" feature; what would be expressed by an output signal is, in practice, expressed by the automatic ports of the registers and fields whose properties expose values to the outside world.
