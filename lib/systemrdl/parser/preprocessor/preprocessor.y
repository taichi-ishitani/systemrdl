class SystemRDL::Parser::Preprocessor::GeneratedPreprocessor
token
  # Keywords
  KW_ABSTRACT KW_ACCESSTYPE KW_ADDRESSINGTYPE KW_ADDRMAP KW_ALIAS
  KW_ALL KW_BIT KW_BOOLEAN KW_BOTHEDGE KW_COMPACT
  KW_COMPONENT KW_COMPONENTWIDTH KW_CONSTRAINT KW_DEFAULT KW_ENCODE
  KW_ENUM KW_EXTERNAL KW_FALSE KW_FIELD KW_FULLALIGN
  KW_HW KW_INSIDE KW_INTERNAL KW_LEVEL KW_LONGINT
  KW_MEM KW_NA KW_NEGEDGE KW_NONSTICKY KW_NUMBER
  KW_ONREADTYPE KW_ONWRITETYPE KW_POSEDGE KW_PROPERTY KW_R
  KW_RCLR KW_REF KW_REG KW_REGALIGN KW_REGFILE
  KW_RSET KW_RUSER KW_RW KW_RW1 KW_SIGNAL
  KW_STRING KW_STRUCT KW_SW KW_THIS KW_TRUE
  KW_TYPE KW_UNSIGNED KW_W KW_W1 KW_WCLR
  KW_WOCLR KW_WOSET KW_WOT KW_WR KW_WSET
  KW_WUSER KW_WZC KW_WZS KW_WZT
  # Literal
  STRING
  NUMBER
  VERILOG_NUMBER
  # Identifier
  SIMPLE_ID
  # Conrol tokens
  EOS

rule
  source_description
    : source_item+ EOS {
      result = [*val[..-2].flatten, val[-1]]
    }

  source_item
    : rdl_token+ {
      result = val
    }

  rdl_token
    : rdl_keyword | rdl_literal | rdl_symbol

  rdl_keyword
    : KW_ABSTRACT | KW_ACCESSTYPE | KW_ADDRESSINGTYPE | KW_ADDRMAP | KW_ALIAS
    | KW_ALL | KW_BIT | KW_BOOLEAN | KW_BOTHEDGE | KW_COMPACT
    | KW_COMPONENT | KW_COMPONENTWIDTH | KW_CONSTRAINT | KW_DEFAULT | KW_ENCODE
    | KW_ENUM | KW_EXTERNAL | KW_FALSE | KW_FIELD | KW_FULLALIGN
    | KW_HW | KW_INSIDE | KW_INTERNAL | KW_LEVEL | KW_LONGINT
    | KW_MEM | KW_NA | KW_NEGEDGE | KW_NONSTICKY | KW_NUMBER
    | KW_ONREADTYPE | KW_ONWRITETYPE | KW_POSEDGE | KW_PROPERTY | KW_R
    | KW_RCLR | KW_REF | KW_REG | KW_REGALIGN | KW_REGFILE
    | KW_RSET | KW_RUSER | KW_RW | KW_RW1 | KW_SIGNAL
    | KW_STRING | KW_STRUCT | KW_SW | KW_THIS | KW_TRUE
    | KW_TYPE | KW_UNSIGNED | KW_W | KW_W1 | KW_WCLR
    | KW_WOCLR | KW_WOSET | KW_WOT | KW_WR | KW_WSET
    | KW_WUSER | KW_WZC | KW_WZS | KW_WZT

  rdl_literal
    : STRING | NUMBER | VERILOG_NUMBER | SIMPLE_ID

  rdl_symbol
    : "[" | "]" | "(" | ")" | "{" | "}"
    | "!" | "&&" | "||" | "<" | ">" | "<=" | ">=" | "==" | "!=" | ">>" | "<<"
    | "~" | "&" | "~&" | "|" | "~|" | "^" | "~^" | "^~" | "*" | "/" | "%" | "+" | "-" | "**"
    | "?" | ":" | "->" | "." | "," | "'" | ";" | "=" | "@" | "+=" | "%="
