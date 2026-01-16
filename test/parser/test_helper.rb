# frozen_string_literal

require_relative '../test_helper'

module SystemRDL
  module Parser
    class TestCase < Minitest::Test
      include ::AST::Sexp

      def assert_parses(ast, code, **optargs)
        result = SystemRDL::Parser.parse(code, **optargs)
        assert_equal(ast, result)
      end

      def assert_raises_parse_error(code, **optargs)
        assert_raises(Racc::ParseError) do
          SystemRDL::Parser.parse(code, **optargs)
        end
      end
    end
  end
end
