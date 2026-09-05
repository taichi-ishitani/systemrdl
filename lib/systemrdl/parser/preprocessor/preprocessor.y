class SystemRDL::Parser::Preprocessor::GeneratedPreprocessor
token
  # Directives
  PP_IFDEF PP_IFNDEF PP_ELSIF PP_ELSE PP_ENDIF PP_DEFINE
  PP_UNDEF PP_INCLUDE PP_MACRO_ID PP_NL
  # Literal
  STRING
  NUMBER
  VERILOG_NUMBER
  # Identifier
  SIMPLE_ID
  # Conrol tokens
  NL
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
    | text_macro_definition
    | text_macro_call
    | undef
    | ifdef
    | ifndef
    | include

  rdl_tokens
    : rdl_token+ {
        result = RdlTokens.new(val[0])
      }
  rdl_token
    : rdl_literal | rdl_symbol
    | "[" | "]" | "(" | ")" | "{" | "}" | ","
  rdl_literal
    : STRING | NUMBER | VERILOG_NUMBER | SIMPLE_ID
  rdl_symbol
    : "!" | "&&" | "||" | "<" | ">" | "<=" | ">=" | "==" | "!=" | ">>" | "<<"
    | "~" | "&" | "~&" | "|" | "~|" | "^" | "~^" | "^~" | "*" | "/" | "%" | "+" | "-" | "**"
    | "?" | ":" | "->" | "." | "'" | ";" | "=" | "@" | "+=" | "%="

  pp_keyword
    : PP_IFDEF | PP_IFNDEF | PP_ELSIF | PP_ELSE | PP_ENDIF | PP_DEFINE | PP_INCLUDE

  #
  # `define
  #
  text_macro_definition
    : text_macro_start text_macro_header text_macro_body {
        result = Define.new(val[1][0], val[1][1], val[2])
      }
  text_macro_start
    : PP_DEFINE {
        enter_macro_body
        result = val[0]
      }
  text_macro_header
    : SIMPLE_ID "(" text_macro_params ")" {
        result = [val[0], val[2]]
      }
    | SIMPLE_ID {
        result = [val[0]]
      }
  text_macro_params
    : SIMPLE_ID ("," SIMPLE_ID)* {
        result = collect_list_items(val)
      }
  text_macro_body
    : text_macro_token* (PP_NL text_macro_token*)* NL {
        exit_macro_body
        result = val.flatten
      }
  text_macro_token
    : rdl_token | pp_keyword | PP_MACRO_ID

  text_macro_call
    : PP_MACRO_ID {
        result = MacroCall.new(val[0], nil, nil, nil)
      }
    | PP_MACRO_ID "(" ")" {
        result = MacroCall.new(val[0], nil, val[1], val[2])
      }
    | PP_MACRO_ID "(" text_macro_args ")" {
        result = MacroCall.new(val[0], val[2], nil, nil)
      }
  text_macro_args
    : text_macro_arg ("," text_macro_arg)* {
        result = collect_list_items(val)
      }
  text_macro_arg
    : (text_macro_simple_arg_element | text_macro_bracketed_arg_group)+ {
        result = val[0].flatten
      }
  text_macro_simple_arg_element
    : rdl_literal | rdl_symbol | pp_keyword | PP_MACRO_ID
  text_macro_bracketed_arg_group
    : "(" (text_macro_simple_arg_element | text_macro_bracketed_arg_group | ",")* ")" {
        result = val.flatten
      }
    | "[" (text_macro_simple_arg_element | text_macro_bracketed_arg_group | ",")* "]" {
        result = val.flatten
      }
    | "{" (text_macro_simple_arg_element | text_macro_bracketed_arg_group | ",")* "}" {
        result = val.flatten
      }

  #
  # `undef
  #
  undef
    : PP_UNDEF SIMPLE_ID {
        result = Undef.new(val[1])
      }

  #
  # `ifdef/`ifndef
  #
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

  #
  # `include
  #
  include
    : PP_INCLUDE STRING {
        result = Include.new(val[1])
      }
