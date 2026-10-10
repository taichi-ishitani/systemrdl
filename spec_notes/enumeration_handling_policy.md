# Enumeration Handling Policy

## Overview

This document records this implementation's policy on user-defined
enumerations, covering the scope of enum type checking and the width of an
enum type. It identifies the silent and inconsistent areas in the
specification and states the chosen interpretation together with its
justification.

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
expressions that give the values of its enumerators.

```systemrdl
enum ab {
    A = 0,          // unsized -> longint unsigned -> 64
    B = 128'd1      // 128
};                  // ab is 128 bits wide
```

- An enumerator such as `128'd0`, whose declared width exceeds what its value
  requires, retains its declared width. The bit count is not recomputed from
  the value.
- An automatically assigned enumerator is treated as `longint unsigned`, i.e.
  64 bits (6.2.5.2).
- An ordinary enum, whose enumerators are all unsized literals or
  automatically assigned, is therefore 64 bits wide.

### 2.4 Extent of the Deviation

Only two points lack a basis in the specification: that an enum type has a
width at all, and that the width is the maximum of the declared widths of its
enumerators. The width of each individual enumerator follows directly from
the self-determined width rule of 7.3.1.

---

## 3. Remaining Silent Areas

### 3.1 The Width of `A = 0;`

Table 7 defines `bit` as an unsigned integer with the value 0 or a
Verilog-style number, and `longint unsigned` as an unsized number (4.6 a-b),
leaving the classification of the literal `0` unclear. This implementation
treats unsized integer literals, including `0`, as `longint unsigned`, i.e.
64 bits wide. This follows the general policy for expression evaluation and
is not specific to enums.

### 3.2 Collisions During Automatic Value Assignment

6.2.5.2 states that automatically assigned values cannot break the unique
value constraint, but does not specify the treatment of a case such as
`{ A = 1; B = 0; C; }`, where the collision arises.
