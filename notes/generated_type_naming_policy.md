# Generated Type Naming Policy

This document records how this implementation handles clause 5.1.1.4 ("Generated type naming rules") of the SystemRDL 2.0 specification, and how the underlying need that the clause addresses is met by other means.

## Background

Clause 5.1.1.4 prescribes a procedure for constructing the elaborated type name of an instance that has parameter arguments. When the resolved arguments differ from the type's default parameter values, the procedure appends each parameter's name together with a normalized value to the original type name. Normalization is hex for integers, `t`/`f` for booleans, the first eight characters of an MD5 checksum for strings, and similar fixed forms for arrays, structs, and enums.

The clause's stated motivation is to provide "a minimum level of compatibility between tool outputs" by defining how generation targets uniquely identify instance types.

## Decision

This implementation does not follow 5.1.1.4. No string of the form prescribed by the clause is constructed or carried through the elaboration process. The rationale below explains why this is sufficient.

## Rationale

How a concretized type is represented internally is an implementation detail of the elaborator. Once parameter values are resolved (and after any dynamic property assignments have been applied), the resulting instance is fully described by its concrete component and the values of its properties. No separate string label is required for the elaborator or downstream code to reason about that instance.

The practical use case that a standardized type name would address -- sharing a single C struct or UVM RAL class across structurally identical instances -- can simply be skipped. Emitting one struct or class per instance is more verbose but harmless; the generated artifacts remain correct. There is no obligation to deduplicate.

When deduplication is desired, a standardized string identifier is not the right tool. Comparing the elaborated objects directly, looking at their concrete component and resolved property values, suffices to decide equivalence. When a stable handle is needed for naming or indexing, a hash computed from those objects yields one without the spec's normalization procedure. Such a hash is an internal implementation detail and need not match across tools.

This implementation does not plan to expose a public API into the elaboration process. The elaboration is treated as an internal step whose externally consumed product is the concrete instance tree. There is therefore no public surface on which a standardized type-name string would be required to appear.

Should external access to intermediate state become necessary in the future, the natural form is to expose the concrete type object itself, whose identity and properties can be inspected directly. Encoding type information into a string identifier remains unnecessary in that scenario as well.

## Status

By default, this implementation does not provide any facility for deciding the identity of concretized instances. The internal handling described above is enough for the elaborator's own purposes, and external consumers are not expected to need such a facility either.

If a concrete external requirement for instance identification does arise, the response will be developed at that point along the lines sketched in Rationale -- direct comparison of elaborated objects, an implementation-internal hash, or exposing the concrete type object itself. Until then, no such facility is offered or planned.
