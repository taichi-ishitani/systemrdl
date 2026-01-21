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
  left "**"
  left "*" "/" "%"
  left "<<" ">>"
  left "<" "<=" ">" ">="
  left "==" "!="
  left "&"
  left "^" "~^" "^~"
  left "|"
  left "&&"
  left "||"
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
        result = create_node(:instance_ref, to_list(val, include_separator: true), val)
      }
  prop_ref
    : instance_ref "->" id {
        result = create_node(:prop_ref, [val[0], val[2]], val)
      }
  instance_or_prop_ref
    : prop_ref
    | instance_ref
  instance_ref_element
    : id array* {
      result = create_node(:instance_ref_element, to_list(val, include_separator: false), val)
    }

  #
  # B.12 Array and range
  #
  array
    : "[" constant_expression "]" {
        result = create_node(:array, [val[1]], val)
      }

  #
  # B.15 Literals
  #
  primary_literal
    : boolean_literal {
        result = create_node(:boolean, val, val)
      }
    | STRING {
        result = create_node(:string, val, val)
      }
    | NUMBER {
        result = create_node(:number, val, val)
      }
    | VERILOG_NUMBER {
        result = create_node(:verilog_number, val, val)
      }
    | accesstype_literal {
        result = create_node(:access_type, val, val)
      }
    | onreadtype_literal {
        result = create_node(:on_read_type, val, val)
      }
    | onwritetype_literal {
        result = create_node(:on_write_type, val, val)
      }
    | addressingtype_literal {
        result = create_node(:addressing_type, val, val)
      }
    | precedencetype_literal {
        result = create_node(:precedence_type, val, val)

      }
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
    | constant_expression binary_operator constant_expression {
        result = create_node(:binary_operation, [val[1], val[0], val[2]], val)
      }
    | unary_operator constant_expression = UOP {
        result = create_node(:unary_operation, val, val)
      }
  constant_primary
    : primary_literal
    | "(" constant_expression ")" {
        val[1].replace_range(to_token_range(val))
      }
    | instance_or_prop_ref
  binary_operator
    : "&&" | "||" | "<" | ">" | "<=" | ">=" | "==" | "!=" | ">>" | "<<"
    | "&" | "|" | "^" | "~^"| "^~" | "*" | "/" | "%" | "+" | "-" | "**"
  unary_operator
    : "!" | "+" | "-" | "~" | "&" | "~&" | "|" | "~|" | "^" | "~^" | "^~"

  #
  # B.17 Identifiers
  #
  id
    : SIMPLE_ID {
        result = create_node(:id, val, val)
      }
