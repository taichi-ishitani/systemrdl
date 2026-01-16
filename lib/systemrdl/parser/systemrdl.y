class SystemRDL::Parser::GeneratedParser
token
  BOOLEAN
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
  boolean_literal
    : BOOLEAN {
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
