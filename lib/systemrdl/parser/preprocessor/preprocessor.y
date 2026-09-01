class SystemRDL::Parser::Preprocessor::GeneratedPreprocessor
token
  # Directives
  PP_IFDEF PP_IFNDEF PP_ELSIF PP_ELSE PP_ENDIF PP_DEFINE
  PP_INCLUDE PP_MACRO_ID
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
  root
    : source_description EOS {
        result = Root.new(val[0], val[1])
      }

  source_description
    : source_item+ {
        result = SourceDescription.new(val[0])
      }

  source_item
    : rdl_tokens
    | define
    | ifdef
    | ifndef
    | include

  rdl_tokens
    : rdl_token+ {
        result = RdlTokens.new(val[0])
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

  define
    : PP_DEFINE SIMPLE_ID {
        result = Define.new(val[1])
      }

  ifdef
    : PP_IFDEF SIMPLE_ID source_description elsif* else? PP_ENDIF {
        if_branch = [val[1], false, val[2]]
        result = Ifdef.new(if_branch, val[3], val[4])
      }
  ifndef
    : PP_IFNDEF SIMPLE_ID source_description elsif* else? PP_ENDIF {
      if_branch = [val[1], true, val[2]]
      result = Ifdef.new(if_branch, val[3], val[4])
    }
  elsif
    : PP_ELSIF SIMPLE_ID source_description {
        result = [val[1], false, val[2]]
      }
  else
    : PP_ELSE source_description {
        result = val[1]
      }

  include
    : PP_INCLUDE STRING {
        result = Include.new(val[1])
      }
