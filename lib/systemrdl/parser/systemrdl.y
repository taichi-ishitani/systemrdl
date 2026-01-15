class SystemRDL::Parser::GeneratedParser
token
  BOOLEAN

rule
  root
    : test_expression

  test_expression
    : expression {
        if test?
          val[0]
        else
          # todo
        end
      }

  expression
    : primary_literal

  primary_literal
    : boolean_literal
  boolean_literal
    : BOOLEAN {
        result = AST::Boolean.new(val[0])
      }
