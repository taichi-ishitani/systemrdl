# Alias Register Handling Policy

This document records implementation policy for SystemRDL alias registers in areas where the specification is silent. It complements `alias_register_support.md`, which covers the RTL and UVM RAL structure of alias registers; this document focuses on behavioral choices that the specification does not pin down.

## Scope

The policy here is binding on the backend (RTL/UVM generator) rather than on the elaborator. The elaborator's responsibility is to preserve, in the elaborated tree, the structure of an alias register: which fields it declares, which fields it omits relative to its primary, and the alias-specific software access properties. The behavior described below is how the backend then realizes that structure in generated code.

## Access to Fields Omitted by an Alias

### Background

Specification clause 10.5.1 (c) permits an alias register to omit fields that exist in its primary register:

> The alias register is not required to have all the fields from the primary register.

The specification does not, however, describe what should happen when software accesses an alias register at the bit positions corresponding to those omitted fields. The physical storage still exists -- alias registers share a single physical implementation with their primary (10.5 introduction) -- but the alias "window" does not expose those positions.

The relevant question for the backend is: when software issues a read or a write through the alias address, and those accesses cover bit positions corresponding to fields that the alias has omitted, what should happen at those positions?

### Decision

When software accesses an alias register at a bit position corresponding to a field that the alias has omitted (i.e. a field that exists in the primary but is not declared in the alias):

- **Write**: the access is ignored at that position. No write strobe is propagated to the primary's storage for the omitted bits, and no software-write side effect (e.g. `woclr`, `woset`, `onwrite`) is triggered.
- **Read**: the access has no side effect at that position. No software-read side effect (e.g. `rclr`, `rset`, `onread`) is triggered on the primary's field. The returned read data value for those positions is not specified by this policy; only the absence of side effects is required.

This applies regardless of the omitted field's primary-side properties: even if the corresponding primary field has `rclr`, `woclr`, or other side-effect properties, those side effects are not invoked by accesses through the alias at omitted positions.

### Rationale

From the perspective of a software programmer using the alias, an omitted field does not exist in this register. The alias presents a particular subset of the primary as its visible interface; bits not exposed by the alias are not part of what the alias claims to be. Triggering side effects (clearing on read, setting on write, etc.) at those positions through the alias would violate that presentation: the programmer would be causing changes to fields that, from the alias's interface, are not there.

This view aligns with the spec's framing in 10.5 that "accessibility of this register may be different in each location" and that software access properties may differ between primary and alias. Omitting a field from an alias is a stronger form of that location-specific accessibility: not just a different access type, but no access at all through this window.

Implementing this requires the backend's decode and side-effect logic to be gated by the alias's field set: the alias's decode path produces write strobes and read-side-effect triggers only for the bit positions that the alias actually declares. The primary's access path is unaffected; accesses through the primary continue to trigger its side effects normally.

### Status

This is not a specification-mandated rule. Clause 10.5 does not address access to omitted-field positions. The decision here is a backend implementation policy chosen to keep the alias's behavior consistent with the interface it presents to software, and to avoid surprising side effects on fields that are not visible through the alias.

If future use cases require different semantics (for example, propagating writes to the primary's storage even at omitted positions, treating the alias purely as an access-control window without affecting side-effect routing), this policy should be revisited. Because the basis is an interpretation rather than a specification rule, alternative implementations would not contradict the specification.
