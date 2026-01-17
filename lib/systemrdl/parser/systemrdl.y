class SystemRDL::Parser::GeneratedParser
token
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
  STRING
  NUMBER
  VERILOG_NUMBER

rule
  root
    : test_expression

  test_expression
    : expression {
        unless test?
          # todo
          # report parse error
        end
      }

  expression
    : primary_literal

  primary_literal
    : boolean_literal
    | string_literal
    | number_literal
    | accesstype_literal
    | onreadtype_literal
    | onwritetype_literal
    | addressingtype_literal
    | precedencetype_literal
  boolean_literal
    : TRUE {
        result = AST::Boolean.new(val[0])
      }
    | FALSE {
        result = AST::Boolean.new(val[0])
      }
  string_literal
    : STRING {
        result = AST::String.new(val[0])
      }
  number_literal
    : NUMBER {
        result = AST::Number.new(val[0])
      }
    | VERILOG_NUMBER {
        result = AST::VerilogNumber.new(val[0])
      }
  accesstype_literal
    : NA {
        result = AST::AccessType.new(val[0])
      }
    | RW {
        result = AST::AccessType.new(val[0])
      }
    | WR {
        result = AST::AccessType.new(val[0])
      }
    | R {
        result = AST::AccessType.new(val[0])
      }
    | W {
        result = AST::AccessType.new(val[0])
      }
    | RW1 {
        result = AST::AccessType.new(val[0])
      }
    | W1 {
        result = AST::AccessType.new(val[0])
      }
  onreadtype_literal
    : RCLR {
        result = AST::OnReadType.new(val[0])
      }
    | RSET {
        result = AST::OnReadType.new(val[0])
      }
    | RUSER {
        result = AST::OnReadType.new(val[0])
      }
  onwritetype_literal
    : WOSET {
        result = AST::OnWriteType.new(val[0])
      }
    | WOCLR {
        result = AST::OnWriteType.new(val[0])
      }
    | WOT {
        result = AST::OnWriteType.new(val[0])
      }
    | WZS {
        result = AST::OnWriteType.new(val[0])
      }
    | WZC {
        result = AST::OnWriteType.new(val[0])
      }
    | WZT {
        result = AST::OnWriteType.new(val[0])
      }
    | WCLR {
        result = AST::OnWriteType.new(val[0])
      }
    | WSET {
        result = AST::OnWriteType.new(val[0])
      }
    | WUSER {
        result = AST::OnWriteType.new(val[0])
      }
  addressingtype_literal
    : COMPACT {
        result = AST::AddressingType.new(val[0])
      }
    | REGALIGN {
        result = AST::AddressingType.new(val[0])
      }
    | FULLALIGN {
        result = AST::AddressingType.new(val[0])
      }
  precedencetype_literal
    : HW {
        result = AST::PrecedenceType.new(val[0])
      }
    | SW {
        result = AST::PrecedenceType.new(val[0])
      }
