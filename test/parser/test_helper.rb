# frozen_string_literal

require_relative '../test_helper'

module SystemRDL
  module Parser
    class TestCase < Minitest::Test
      include ::AST::Sexp

      def s(type, *children)
        children = children.map do |child|
          child.is_a?(::String) && Token.new(child, nil, nil) || child
        end
        super(type, *children)
      end

      def assert_parses(ast, code, **optargs)
        result = SystemRDL::Parser.parse(code, **optargs)
        assert_equal(ast, result)
      end

      def assert_raises_parse_error(code, **optargs)
        assert_raises(SystemRDL::ParseError) do
          SystemRDL::Parser.parse(code, **optargs)
        end
      end
    end
  end
end
