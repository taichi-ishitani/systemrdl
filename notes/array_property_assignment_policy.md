# Array Property Assignment Policy

## Overview

SystemRDL allows a property to be dynamically assigned to an array instance, either to every element at once or to an individual element (5.1.3.3 d) 2)). This document records how this implementation restricts such assignments.

The restrictions exist because an array is, by the specification's own addressing model, a *uniform repetition*: a single element shape -- its `size`, `accesswidth`, and software-access character -- repeated at a regular stride. The addressing rules rely on this uniformity. A per-element assignment that changes a property affecting placement or type would break that uniformity, producing something that is no longer a uniform array in the elaborated model. The specification permits per-element assignment syntactically but does not reconcile it with the uniform-array model; this policy resolves that gap on the side of preserving uniformity.

The specification's own example of per-element assignment (5.1.3.3 Example 2) assigns only `name` -- a purely descriptive property. This implementation follows that lead: per-element assignment is allow-listed, defaulting to descriptive properties only.

## Assignment Cases

The treatment depends on the form of the left-hand side (the assignment target) and, for whole-array assignment, on the form of the right-hand side.

### Left-hand side is a single array element (`a[i]->prop`)

Allowed only for allow-listed properties. The initial allow list is descriptive properties that affect neither placement, type, nor software-access character: `name`, `desc`.

Properties outside the list -- `accesswidth` (affects placement/stride and sub-word boundary), `sw`, `hw` (affect the access side and register type), and so on -- are rejected when assigned per element, because differing values across elements break the array's uniformity.

This applies equally when the target is a field reached through an array element (`a[i].f->prop`): the target property being a field property rather than a register property does not change the judgment. The same allow list governs; `sw`/`hw` on a field remain outside it.

### Left-hand side is the whole array (`a->prop`)

Allowed for all properties. A whole-array assignment gives every element the same value, so it cannot break uniformity, and no property restriction is needed. The right-hand side, however, is constrained:

- Right-hand side is a value, a non-array instance, or a single array element (e.g. `b[0].x`): **allowed**. The right-hand side denotes a single thing, so the correspondence is unambiguous.
- Right-hand side is a whole array (e.g. `a->swwe = b`): **rejected** (currently). If element counts matched, an element-wise correspondence `a[i] <- b[i]` might be meaningful, but the specification does not define this, so it is left as a future consideration and rejected for now.

### Left-hand side is a non-array instance (`s->prop`)

Ordinary dynamic assignment (outside the scope of these array restrictions), with one array-related case:

- Right-hand side is a single array element (`b[0].x`): allowed (denotes a single thing).
- Right-hand side is a whole array (`s->prop = b`): rejected -- a single target cannot correspond to a whole array. This is the same reasoning as the rejected whole-array right-hand side above: any single-valued left-hand side (a scalar or a single array element) cannot take a whole array on the right.

## Rationale Summary

The following table summarizes the treatment by the form of the left-hand side (LHS, the target) and right-hand side (RHS, the assigned value):

| LHS \ RHS | Value / non-array instance | Single array element (`b[i].x`) | Whole array (`b`) |
|---|---|---|---|
| **Single array element** (`a[i]->p`) | Allow-listed only (`name`, `desc`) | Allow-listed only | Error |
| **Whole array** (`a->p`) | Allowed (all properties) | Allowed (all properties) | Error (under consideration) |
| **Non-array** (`s->p`) | Allowed (ordinary assignment) | Allowed | Error |

Notes: a single-valued LHS (a single array element or a non-array instance) cannot take a whole array on the RHS, so those cells are errors. The whole-array LHS with a whole-array RHS is the one case that might later be defined (element-wise correspondence when counts match); it is rejected for now. A field reached through an array element (`a[i].f->p`) follows the single-array-element row.

- **Per-element assignment is allow-listed** because differing per-element values of a placement- or type-affecting property break the uniform-array model. Defaulting to descriptive properties (`name`, `desc`) matches the only example the specification gives.
- **Whole-array assignment is unrestricted by property** because all elements receive the same value; uniformity is preserved regardless of which property.
- **A whole-array right-hand side is rejected** unless a defined element-wise correspondence exists -- which, for now, none does.
- The direction of these choices is deliberately toward rejection: an over-restriction can be relaxed later without breaking existing input, whereas admitting an ill-defined assignment and later constraining it would not be backward-compatible. This is especially safe against user-defined properties, whose placement/type impact the elaborator cannot assess: an unknown property is simply not on the per-element allow list.

## Under Consideration (Currently Rejected)

- **Whole-array to whole-array assignment** (`a->prop = b`): the element-wise correspondence semantics are undefined by the specification. Revisit if and when that correspondence is given a defined meaning (e.g. `a[i] <- b[i]` for matching element counts); until then it stays an error.
- **Expanding the per-element allow list** beyond `name`/`desc` -- e.g. `reset`, which is a value that affects neither placement nor type. The specification does not example per-element `reset` on a register array (its Example 3 assigns `reset` to a *field* array, treated as non-array per 5.1.3.3 d) 1)), so any addition rests on this implementation's own harmlessness judgment rather than on a specification example.
