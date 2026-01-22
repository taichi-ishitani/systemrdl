class SystemRDL::Parser::GeneratedParser
token
  # Keywords
  ABSTRACT ACCESSTYPE ADDRESSINGTYPE ADDRMAP ALIAS
  ALL BIT BOOLEAN BOTHEDGE COMPACT
  COMPONENT COMPONENTWIDTH CONSTRAINT DEFAULT ENCODE
  ENUM EXTERNAL FALSE FIELD FULLALIGN
  HW INSIDE INTERNAL LEVEL LONGINT
  MEM NA NEGEDGE NONSTICKY NUMBER
  ONREADTYPE ONWRITETYPE POSEDGE PROPERTY R
  RCLR REF REG REGALIGN REGFILE
  RSET RUSER RW RW1 SIGNAL
  STRING STRUCT SW THIS TRUE
  TYPE UNSIGNED W W1 WCLR
  WOCLR WOSET WOT WR WSET
  WUSER WZC WZS WZT
  # Other tokens
  STRING
  NUMBER
  VERILOG_NUMBER
  SIMPLE_ID

prechigh
  nonassoc UOP
  left     "**"
  left     "*" "/" "%"
  left     "+" "-"
  left     "<<" ">>"
  left     "<" "<=" ">" ">="
  left     "==" "!="
  left     "&"
  left     "^" "~^" "^~"
  left     "|"
  left     "&&"
  left     "||"
  right    "?" ":"
preclow

rule
  root
    : test_expression

  test_expression
    : constant_expression {
        unless test?
          parse_error(val[0].range.head)
        end
        result = val[0]
      }

  #
  # B.11 Reference
  #
  instance_ref
    : instance_ref_element ("." instance_ref_element)* {
        result = node(:instance_ref, to_list(val, include_separator: true), val)
      }
  prop_ref
    : instance_ref "->" id {
        result = node(:prop_ref, [val[0], val[2]], val)
      }
  instance_or_prop_ref
    : prop_ref
    | instance_ref
  instance_ref_element
    : id array* {
      result = node(:instance_ref_element, to_list(val, include_separator: false), val)
    }

  #
  # B.12 Array and range
  #
  array
    : "[" constant_expression "]" {
        result = node(:array, [val[1]], val)
      }

  #
  # B.13 Concatenation
  #
  constant_concatenation
    : "{" constant_expression ("," constant_expression)* "}" {
        result = node(:concatenation, to_list(val[1..-2], include_separator: true), val)
      }
  constant_multiple_concatenation
    : "{" constant_expression constant_concatenation "}" {
      result = node(:replication, val[1..2], val)
    }

  #
  # B.15 Literals
  #
  boolean_literal
    : TRUE | FALSE
  accesstype_literal
    : NA | RW | WR | R | W | RW1 | W1
  onreadtype_literal
    : RCLR | RSET | RUSER
  onwritetype_literal
    : WOSET | WOCLR | WOT | WZS | WZC | WZT | WCLR | WSET | WUSER
  addressingtype_literal
    : COMPACT | REGALIGN | FULLALIGN
  precedencetype_literal
    : HW | SW

  #
  # B.16 Expressions
  #
  constant_expression
    : constant_primary
    | "!" constant_expression = UOP {
        result = uop_node(val)
      }
    | "+" constant_expression = UOP {
        result = uop_node(val)
      }
    | "-" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~" constant_expression = UOP {
        result = uop_node(val)
      }
    | "&" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~&" constant_expression = UOP {
        result = uop_node(val)
      }
    | "|" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~|" constant_expression = UOP {
        result = uop_node(val)
      }
    | "^" constant_expression = UOP {
        result = uop_node(val)
      }
    | "~^" constant_expression = UOP {
        result = uop_node(val)
      }
    | "^~" constant_expression = UOP {
        result = uop_node(val)
      }
    | constant_expression "&&" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "||" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "<" constant_expression {
        result = bop_node(val)
      }
    | constant_expression ">" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "<=" constant_expression {
        result = bop_node(val)
      }
    | constant_expression ">=" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "==" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "!=" constant_expression {
        result = bop_node(val)
      }
    | constant_expression ">>" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "<<" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "&" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "|" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "^" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "~^" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "^~" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "*" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "/" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "%" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "+" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "-" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "**" constant_expression {
        result = bop_node(val)
      }
    | constant_expression "?" constant_expression ":" constant_expression {
        result = node(:conditional_operation, [val[0], val[2], val[4]], val)
      }
  constant_primary
    : primary_literal
    | constant_concatenation
    | constant_multiple_concatenation
    | "(" constant_expression ")" {
        val[1].replace_range(to_token_range(val))
      }
    | instance_or_prop_ref
  primary_literal
    : boolean_literal {
        result = node(:boolean, val, val)
      }
    | STRING {
        result = node(:string, val, val)
      }
    | NUMBER {
        result = node(:number, val, val)
      }
    | VERILOG_NUMBER {
        result = node(:verilog_number, val, val)
      }
    | accesstype_literal {
        result = node(:access_type, val, val)
      }
    | onreadtype_literal {
        result = node(:on_read_type, val, val)
      }
    | onwritetype_literal {
        result = node(:on_write_type, val, val)
      }
    | addressingtype_literal {
        result = node(:addressing_type, val, val)
      }
    | precedencetype_literal {
        result = node(:precedence_type, val, val)
      }
    | THIS {
        result = node(:this, val, val)
    }

  #
  # B.17 Identifiers
  #
  id
    : SIMPLE_ID {
        result = node(:id, val, val)
      }
