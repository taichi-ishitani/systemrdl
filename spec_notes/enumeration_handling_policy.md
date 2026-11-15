# Enumeration Handling Policy

## Overview

This document records this implementation's policy on user-defined
enumerations, covering the scope of enum type checking, the width of an enum
type, and the expressions that may appear inside an enum definition. It
identifies the silent and inconsistent areas in the specification and states
the chosen interpretation together with its justification.

---

## 1. Scope of Type Checking

### 1.1 Specification Text

Specification 6.2.5.3 states:

> Enumerated types are strongly typed, therefore user-defined properties,
> struct members, or parameters of a given enumerated type are type-checked
> when used in assignments or with relational operators. In other expression
> contexts, enumerators are automatically cast to their integral values.

### 1.2 Chosen Interpretation

Type checking is performed in assignment contexts only. Relational and
equality operators are not type checked.

| Context | Behavior |
|---|---|
| Assignment to an enum-typed UDP | Type checked (15.2.1 d) |
| Actual argument of an enum-typed parameter | Type checked |
| Assignment to an enum-typed struct member | Type checked |
| Relational operators (`<` `<=` `>` `>=`) | Not type checked; operands are cast to integers and compared |
| Equality operators (`==` `!=`) | Not type checked; operands are cast to integers and compared |
| Arithmetic operators and other expression contexts | Operands are cast to integers |

### 1.3 Rationale

6.2.5.3 does require type checking for relational operators, so this is a
deviation from the specification.

The rule is inherited from SystemVerilog, where the corresponding passage in
IEEE 1800 likewise states that enumerated variables are type checked in
assignments, arguments, and relational operators. The three major commercial
simulators (Synopsys VCS, Cadence Xcelium, and Siemens Questa) do not
implement that check for relational operators.

---

## 2. Width of an Enum Type

### 2.1 Specification Text

The specification does not define the width of an enum type.

- The grammar has no base type specification (`enum_def ::= enum id
  enum_body ;`, B.7). There is no equivalent of the SystemVerilog
  `typedef enum bit[7:0] {...}` form.
- Neither 6.2.5 nor 6.2.5.1 mentions width. Enumerator values are only
  required to be of an integral type (6.2.5.1 b-2).
- The `enum` row of Table 7 describes only a reference to a user-defined
  enumeration.
- The mention of `longint unsigned` in 6.2.5.2 concerns the bound of
  automatic value assignment; it does not define the width of an enum type.

### 2.2 Silent Area

An enum type may be used as the type of a parameter, a UDP, or a struct
member (6.2.5.3). When such an entity appears as an operand of an expression,
the width must be derived from the operand itself, because 7.3.1 states:

> The size of any self-determined operand is determined by the operand itself
> and independent of the remainder of the expression.

and 7.3.2 states:

> All expressions are evaluated in a self-determined context [...] which
> implies that the left-hand side of a property assignment is never taken
> into consideration when evaluating expressions.

The left-hand side contributes no width. An enum type therefore requires a
notion of width, and the specification provides none.

### 2.3 Chosen Interpretation

The width of an enum type is the maximum of the self-determined widths of the
expressions that explicitly give the values of its enumerators. An enumerator
whose value is assigned automatically contributes no width of its own; it
takes the width of the enum it belongs to. When no enumerator carries an
explicit value, the width is 64, matching an unsized literal.

```systemrdl
enum ab {
    A = 0,          // unsized -> longint unsigned -> 64
    B = 128'd1      // 128
};                  // ab is 128 bits wide
```

An enumerator such as `128'd0`, whose declared width exceeds what its value
requires, retains its declared width. The bit count is not recomputed from the
value, since a sized literal is the only way to state the width of an enum in
a language that has no base type specification.

The treatment of automatically assigned enumerators follows from the two
examples in 6.2.5.2. In `myAutoEnum`, where every enumerator is assigned
automatically, the resulting values are written unsized (`first_value = 0`).
In `myPartiallyAssignedEnum`, where some enumerators carry explicit 8-bit
values, the automatically assigned ones are written as 8-bit values
(`a = 8'h0`, `d = 8'h7`). The same enumerator form therefore yields a
different width depending on what the other enumerators declare, which is
only consistent with the width being a property of the enum rather than of
the individual enumerator. Were an automatically assigned enumerator to
contribute 64 bits of its own, a single valueless enumerator would defeat the
only means the language offers for stating a narrower width.

An enumerator whose value is assigned automatically may fall outside the
width so determined, as in `enum e { A = 8'hFF; B; }`, where `B` becomes
`0x100` while the enum is 8 bits wide. 6.2.5.2 constrains automatic
assignment only with respect to uniqueness and says nothing about width.
This implementation rejects such a description. Truncating would silently
produce a value the author did not write, and would in this example collide
with `A`; accepting an out-of-range value would contradict the width the
author stated explicitly.

### 2.4 Extent of the Deviation

Only two points lack a basis in the specification: that an enum type has a
width at all, and that the width is the maximum of the declared widths of its
enumerators. The width of each explicitly assigned enumerator follows directly
from the self-determined width rule of 7.3.1, and the treatment of
automatically assigned enumerators follows the examples in 6.2.5.2.

---

## 3. Expressions Inside an Enum Definition

### 3.1 Silent Area

The values of enumerators and the right-hand sides of their property
assignments are constant expressions, and the specification places no
restriction on what may appear in them. An enum may be defined inside any
component (9.1, 10.1, 11.1, 12.1), so the enclosing component's parameters
are visible from the enum's scope, and so, on the same reading, are the
instances declared alongside it.

### 3.2 Chosen Interpretation

A parameter of the enclosing component may be referenced. An instance
reference, whether to the instance itself or to one of its properties, is
rejected.

```systemrdl
reg my_reg #(longint unsigned BASE = 0) {
    enum e { A = BASE; };       // accepted
    field { sw = rw; hw = r; } f;
    enum g { A = f->fieldwidth; };  // rejected
};
```

### 3.3 Rationale

A parameter belongs to the lexical scope in which the enum is defined and is
part of the type; an instance reference reaches into the elaborated instance
tree, which an enum, being a definition that is never instantiated (6.2.5.1),
sits outside of. 5.1.4 keeps the two in separate namespaces.

The decisive consideration is that an enum defined at the root scope has no
instance tree to reach into at all. Permitting instance references would make
the same enum definition legal or illegal depending on where it is written,
and a definition intended to be shared across scopes would silently acquire
that restriction. Rejecting them uniformly keeps an enum definition to mean
the same thing wherever it appears.

In this implementation the restriction falls out of the type check on
enumerator values: an instance reference and a property reference each carry a
reference type, which is not integral, so 6.2.5.1 b-2 rejects it.

---

## 4. Remaining Silent Areas

### 4.1 The Width of `A = 0;`

Table 7 defines `bit` as an unsigned integer with the value 0 or a
Verilog-style number, and `longint unsigned` as an unsized number (4.6 a-b),
leaving the classification of the literal `0` unclear. This implementation
treats unsized integer literals, including `0`, as `longint unsigned`, i.e.
64 bits wide. This follows the general policy for expression evaluation and
is not specific to enums.

### 4.2 Collisions During Automatic Value Assignment

6.2.5.2 states that automatically assigned values cannot break the unique
value constraint, but does not specify what happens when they do, as in
`{ A = 1; B = 0; C; }`, where `C` is assigned `1` and collides with `A`. This
implementation rejects such a description rather than searching for the next
free value, since any other value would be one the author neither wrote nor
could predict from the text.
