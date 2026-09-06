# Verilog-style preprocessor design notes

This document records the design decisions behind the Verilog-style
preprocessor, together with their rationale.

The preprocessor implements the compiler directives listed in Table 32 of the
SystemRDL 2.0 specification. That table defers the semantics of these directives
to Verilog / SystemVerilog, so the behavior described here follows the
SystemVerilog (IEEE 1800-2012) text-macro and conditional-compilation rules
rather than anything defined by SystemRDL itself. Points where SystemVerilog is
silent, or where this implementation deviates from it, are called out below.

## Why a Racc-based parser

The preprocessor parses directives with a Racc-generated parser rather than an
ad-hoc, hand-written scanner loop.

The main reasons are:

* **Position tracking.** Lexing is performed in the preprocessor stage so that
  every token carries its origin position from the moment it is produced. Macro
  bodies and actual arguments are spliced as tokens that already hold the right
  positions (a body token points into the definition, an argument token into the
  call site), so no position remapping is needed after the fact.
* **Directive and argument structure is not trivial.** Once function-like macros
  are supported, actual-argument lists carry nested brackets, commas that must be
  protected inside matched pairs, and nested macro usages. Expressing these as
  grammar rules is more robust than tracking bracket depth and comma boundaries
  by hand.

Preprocessing is inherently sequential and context dependent: a `` `define ``
updates the macro table, and later `` `ifdef `` / macro usages depend on that
state in source order. This is handled by keeping the macro table in a context
object that is updated as the parse tree is evaluated.

## Deviations from SystemVerilog

### Token joining at the macro-usage boundary

SystemVerilog defines macro expansion as text substitution: the expanded text is
spliced in at the point of use and the result is then lexed. Under that rule,

```
`define foo(s) s
`foo(a)b
```

is equivalent to the text `ab`, which lexes as the single identifier `ab`.

Because this implementation expands macros at the token level rather than as raw
text, the expansion result (`a`) and the following source token (`b`) stay
separate: `` `foo(a)b `` yields two tokens, `a` and `b`, not one token `ab`.

This is an intentional deviation. Joining tokens across the boundary is possible
without giving up token-level positions — the adjacent tokens can be
concatenated and re-lexed, and positions rebuilt from the original tokens (see
"Future work" below). It was left out simply because it is not worth the effort:
the position rebuilding is fiddly, and this construct essentially never appears
in real SystemRDL.

## Behavior where SystemVerilog is unspecified

### One-line comments and line continuation in a macro body

A multi-line macro body continues each line with a trailing backslash, and the
first newline without a preceding backslash ends the body. A one-line comment
(`//`) is not part of the substituted text. SystemVerilog does not spell out how
these interact when a comment sits on a continued line, i.e. whether a backslash
at the end of a `//` comment acts as a line continuation.

Real SystemVerilog simulators were checked, and they treat the trailing
backslash as a line continuation (the continuation is resolved before the
comment is recognized). This implementation follows that behavior:

```
`define foo \
// comment \
"foo"
```

Here the backslash after the comment continues the body, so `"foo"` is part of
`` `foo ``. Without that backslash the body ends at the comment line and `"foo"`
is not included.

### Parenthesized usage of a parameter-less macro

SystemVerilog states that a parameter-less macro substitutes its body for each
occurrence of the macro identifier, and that a function-like macro must be called
with parentheses. It does not say what happens when a parameter-less macro is
used with an empty (or non-empty) argument list, e.g. `` `foo() ``.

Real simulators expand only the macro identifier and leave the parentheses in
place as following source text: `` `define foo 1 `` used as `` `foo() `` becomes
`1()`. This implementation matches that behavior — the parentheses are kept
(with their original positions) after the expanded body — so `` `foo() `` is
handled the same way, and any resulting error (an empty `()` is not a valid
SystemRDL expression) is reported by the downstream parser.

## Unsupported features

The following SystemVerilog macro features are recognized in principle but not
implemented.

* **Token concatenation** (` `` `). Joining adjacent tokens without introducing
  whitespace, to build identifiers from arguments.
* **Macro strings** (`` `" ``, `` `\`" ``). Constructing string literals from
  macro arguments, with argument substitution and embedded-macro expansion
  performed inside the constructed string.

Both are rare in register-map descriptions, and supporting them requires fiddly
handling of position information (see "Future work"). Since the demand is low,
that effort is not considered worthwhile for now, so they are deferred until
there is real demand.

The following are also unsupported:

* **Default values for macro arguments** (`` `define M(a=1) ``). Only macros
  whose actual-argument count matches the formal-argument count are accepted; a
  mismatch is an error.
* **The `` `line `` directive.** Overriding the reported filename and line number
  is not implemented.

## Future work

Notes for implementing the deferred features above, should real demand arise.
The common difficulty is not the processing itself but rebuilding position
information after tokens are transformed.

### Token concatenation and boundary joining

This covers both the explicit `` `` `` operator and the implicit
macro-usage-boundary joining described under "Deviations" above.

The approach:

1. Collect the tokens to be joined (the tokens on both sides of ` `` `, or the
   expansion result and the adjacent following token). For the implicit boundary
   case this collection is itself non-trivial: it requires deciding whether the
   macro usage and the following token are adjacent with no intervening
   whitespace, and following the chain when several joins run together.
2. Concatenate their text and re-lex the concatenated string. Re-lexing lets the
   lexer decide the correct token split (a single token, or several), instead of
   guessing from token kinds.
3. Rebuild the position of each resulting token from the original tokens. When a
   resulting token comes from several original tokens, attribute it to the first
   one. Because the join may change token boundaries, the mapping is best done at
   the character-offset level: record, per character of the concatenated string,
   which original token it came from, and take each resulting token's position
   from its first character.

Re-lexing itself is cheap; the fiddly parts are collecting the tokens to join
and rebuilding their positions, which is why the feature was deferred.

### Whitespace restoration for macro strings

Inside `` `" ``, actual arguments must be substituted into the constructed string
literal with their original whitespace preserved (e.g. `` `msg(left side) ``
must keep the space between `left` and `side`). The token stream discards
inter-token whitespace, so it has to be restored.

Options considered:

* **Recover from source via offsets.** Give each token an offset into its source
  and, at stringification time, take the argument's text (whitespace included)
  directly from the original source. This works only while the argument is a
  contiguous span of a single source; it breaks once the argument mixes tokens
  from different sources (e.g. an argument that itself contains a macro usage,
  whose expansion pulls in tokens from the macro definition).
* **Attach whitespace to tokens.** Have the scanner keep the whitespace it would
  otherwise skip and store it on the following token (in a separate field, so the
  rest of the pipeline is unaffected). Because each token then carries its own
  leading whitespace, the whitespace can be reproduced even when tokens from
  different sources are interleaved. Concatenating the argument's tokens with
  their stored whitespace and stripping the ends restores the argument text.

The second option is the more general one, but attaching whitespace to every
token for the sake of a rarely used feature is a large change, which is why the
feature was deferred.
