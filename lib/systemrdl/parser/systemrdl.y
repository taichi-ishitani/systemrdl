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
  # Symbols
  L_BRACKET R_BRACKET
  ARROW DOT
  # Other tokens
  STRING
  NUMBER
  VERILOG_NUMBER
  SIMPLE_ID

rule
  root
    : test_expression

  test_expression
    : constant_expression {
        unless test?
          # todo
          # report parse error
        end
      }

  #
  # B.11 Reference
  #
  instance_ref
    : instance_ref_element (DOT instance_ref_element)* {
        val = to_list(val, include_separator: true)
        range = to_token_range(val)
        result = AST::InstanceRef.new(range, *val)
      }
  prop_ref
    : instance_ref ARROW id {
        range = to_token_range(val)
        result = AST::PropRef.new(range, val[0], val[2])
      }
  instance_or_prop_ref
    : prop_ref
    | instance_ref
  instance_ref_element
    : id array* {
      val = to_list(val, include_separator: false)
      range = to_token_range(val)
      result = AST::InstanceRefElement.new(range, val[0], *val[1..])
    }

  #
  # B.12 Array and range
  #
  array
    : L_BRACKET constant_expression R_BRACKET {
        range = to_token_range(val)
        result = AST::Array.new(range, val[1])
      }

  #
  # B.15 Literals
  #
  primary_literal
    : boolean_literal {
        range = to_token_range(val[0])
        result = AST::Boolean.new(range, val[0])
      }
    | STRING {
        range = to_token_range(val[0])
        result = AST::String.new(range, val[0])
      }
    | NUMBER {
        range = to_token_range(val[0])
        result = AST::Number.new(range, val[0])
      }
    | VERILOG_NUMBER {
        range = to_token_range(val[0])
        result = AST::VerilogNumber.new(range, val[0])
      }
    | accesstype_literal {
        range = to_token_range(val[0])
        result = AST::AccessType.new(range, val[0])
      }
    | onreadtype_literal {
        range = to_token_range(val[0])
        result = AST::OnReadType.new(range, val[0])
      }
    | onwritetype_literal {
        range = to_token_range(val[0])
        result = AST::OnWriteType.new(range, val[0])
      }
    | addressingtype_literal {
        range = to_token_range(val[0])
        result = AST::AddressingType.new(range, val[0])
      }
    | precedencetype_literal {
        range = to_token_range(val[0])
        result = AST::PrecedenceType.new(range, val[0])

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
  constant_primary
    : primary_literal
    | instance_or_prop_ref

  #
  # B.17 Identifiers
  #
  id
    : SIMPLE_ID {
        range = to_token_range(val[0])
        result = AST::ID.new(range, val[0])
      }
