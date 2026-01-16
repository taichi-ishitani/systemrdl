class SystemRDL::Parser::GeneratedParser
token
  BOOLEAN
  STRING

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
  boolean_literal
    : BOOLEAN {
        result = AST::Boolean.new(val[0])
      }
  string_literal
    : STRING {
        result = AST::String.new(val[0])
      }
