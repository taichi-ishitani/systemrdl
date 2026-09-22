# Component signature

## Purpose

A *signature* identifies a component instance that originates from a **named
component definition**, so that a downstream tool (e.g. an RTL generator) can
decide whether two instances are equivalent and may therefore share a single
generated artifact (e.g. one RTL module).

## Relationship to the specification

SystemRDL 2.0 §5.1.1.3 and §5.1.1.4 define rules for generating a normalized
*type name* for parameterized instances. **These type-name generation rules are
intentionally not implemented.**

Rationale:

- Conformance is unnecessary. The signature only needs to let the backend tell
  instances apart; it does not need to match the specification's type-name
  format to do that.
- Conforming could actually introduce collisions. The specification's
  normalization has weak points for this purpose — for example it uses no
  delimiter between concatenated parameter values, and it shortens a string
  value to a truncated MD5 checksum — so distinct parameter sets can normalize to
  the same string.

## Which instances get a signature

A signature is generated only for instances of a **named** definition.
Instances of an **anonymous** definition do not get one.

The reason is the *expectation of sharing*:

- A **named** definition is a reusable type. Instantiating the same named
  definition with the same parameters yields equal signatures, and the
  expectation is that a single artifact is generated and shared among them.
- An **anonymous** definition is defined in place, for that one use. There is no
  notion of "the same definition used in multiple places", so there is no
  sharing expectation for a signature to serve.

## Structure

A signature has two parts:

- `component_name` — the definition's lexical scope as a list of identifiers,
  from the outermost enclosing definition down to the definition itself.
- `parameter_hash` — a hash of the resolved parameter values (empty string when
  the definition declares no parameters).

Equality of two signatures is structural (both parts equal).

### Parameter value hashing

The resolved parameter values are serialized in definition order and hashed:

1. Each parameter value is stringified (`Value#to_s`). For `bit`-typed values
   (which includes `longint`, handled internally as `bit`), both the value and
   its width are emitted, so that values that are numerically equal but differ in
   width produce different signatures.
2. The pieces are joined with the ASCII Unit Separator (`0x1F`) as a delimiter,
   to keep field boundaries unambiguous without needing a type tag.
3. The joined string is hashed with `Digest::MD5.hexdigest`.

No per-field type tag is needed. Signatures are only ever compared between
instances of the **same** definition. Because they share one definition, the
number, order, and type of the parameters are identical across all such
instances; only the values differ, and each positional field always has the same
type. A `bit` value can never collide with a `string` value at the same position,
so the Unit Separator only needs to disambiguate field boundaries.
