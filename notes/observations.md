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
