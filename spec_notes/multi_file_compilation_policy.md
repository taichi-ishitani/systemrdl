# Multi-File Compilation Policy

This document records how the elaborator handles SystemRDL input that consists of multiple files. The SystemRDL 2.0 specification does not address multi-file compilation; the rules below are an implementation policy chosen to give predictable behavior in its absence.

## Background

A SystemRDL design is often split across multiple files: shared type definitions, user-defined properties, and the actual register/addressmap descriptions are typically kept in separate sources. When such a design is fed to a SystemRDL elaborator, the elaborator must decide what carries across file boundaries and what does not.

The specification states (5.1.4) that a valid SystemRDL description is "an aggregation of nested local scopes, ultimately nested into the outermost global (or root) scope". This suggests a single root scope at the top, but says nothing about whether multiple input files share that root scope or each contributes its own.

In particular, the specification does not say:

- Whether type definitions (component definitions, enums, structs) declared in one file are visible from another file.
- Whether user-defined property declarations from one file are usable in another.
- Whether instances declared at the root scope of one file (e.g. signals) are visible from another.
- Whether default property assignments made at the root scope of one file affect components declared in another.

Different reasonable interpretations are possible -- from full sharing (everything declared at the root scope of any file is visible everywhere) to full isolation (each file is an independent compilation, sharing nothing). The specification leaves the choice to implementations.

## The Shared / Local Distinction

When deciding what to share across files, the relevant axis is not "root scope or not" but "explicitly referenced or implicitly applied":

- A type, a user-defined property, a root-scope instance: these are referenced by name from the user's code. If a file uses `my_reg` or `my_udp`, the user knows that name comes from somewhere and intends to reach it. Sharing such names across files is consistent with the user's intent; isolating them would forbid the common practice of putting shared type definitions in a separate file.
- A root-scope default property assignment (`default hw = r;` outside any component): this is implicitly applied to whatever components happen to be declared in the same enclosing scope. Sharing such assignments across files would mean that adding a `default` line to one file silently changes the meaning of components declared in unrelated files -- a non-local effect that is hard to predict by reading any single file in isolation.

This is the distinction systemrdl-compiler draws in its [Multi-file Compilation notes](https://systemrdl-compiler.readthedocs.io/en/stable/dev_notes/multi_file_compilation.html), and it captures the right trade-off: share what is explicitly named, isolate what is implicitly applied.

## Decision

This elaborator follows the same distinction:

### Shared Across Files

The root namespaces are shared across all input files. Specifically:

- **Type names**: component definitions (`reg`, `regfile`, `addrmap`, `field`, `signal`, `mem`), enum types, and struct types declared at the root scope of any file are visible from all other files.
- **Element names at the root scope**: root-scope instances (signals, etc.) declared in one file are visible from others.
- **Property names**: user-defined property declarations are visible across files.

A name declared in one file may be referenced from another without any import or include directive. Conversely, attempting to redeclare the same name in two files is an error, just as it would be within a single file.

### Local to the Declaring File

Default property assignments made at the root scope of a file are confined to that file:

- A `default <prop> = <value>;` written at the root scope of file A applies to components declared at the root scope of file A (and to nested scopes within those components, per the normal lexical-scope rules of 5.1.3.2).
- The same assignment does not apply to components declared in file B, even if both files are processed in the same elaboration run.
- At the end of processing each file, root-scope default property assignments are discarded; they do not carry over to the next file.

To affect components across multiple files with a default, the assignment must be placed inside a shared addrmap (or other enclosing component) that contains all of them, so that the lexical-scope rule applies uniformly. Root-scope defaults are deliberately local.

## Rationale

The asymmetry -- sharing names but isolating root-scope defaults -- exists because the two have opposite locality requirements.

Names are written for the purpose of being referenced. If a user puts `reg my_reg { ... };` at the root scope of one file and `my_reg inst;` in another, the intent is clear: the second file is reaching out to the first. Isolating names would forbid this common pattern and force every file to redeclare every type it uses.

Root-scope defaults are written for the purpose of applying to whatever happens to be in the same scope. Their effect is not invoked by being named; it is invoked by being present. Sharing this across files would mean that any file containing a `default` line at the root scope silently changes the semantics of unrelated files -- a "spooky action at a distance" that breaks the ability to understand any file by reading it in isolation. Confining root-scope defaults to their declaring file preserves that local readability.

Within a single file, the lexical-scope rules of 5.1.3.2 apply unchanged: a default placed inside an addrmap affects components in that addrmap and its nested scopes, regardless of file boundaries inside the addrmap. The local-to-file rule above only governs defaults placed at the *root* scope, outside any component.

## Status

This policy is an implementation choice; the specification does not mandate it. Other elaborators may make different choices -- for example, fully isolating each file (no name sharing) or fully sharing (root-scope defaults propagate across files). Behavior on multi-file input may therefore differ across tools.

If a SystemRDL design is intended to be portable across elaborators that differ in this area, the safest practice is to avoid relying on either side of the distinction: declare each file's names explicitly where they are used (e.g. via a common type-definition file that is always processed first), and place default property assignments inside enclosing components rather than at the root scope.
