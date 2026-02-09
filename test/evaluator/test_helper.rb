# frozen_string_literal: true

require_relative '../test_helper'

module SystemRDL
  module Evaluator
    class TestCase < Minitest::Test
      def assert_evaluates_value(type, expected, code, **optargs)
        ast = SystemRDL::Parser.parse(code, **optargs)
        output = SystemRDL::Evaluator.evaluate(ast)
        actual = [:type, *expected.keys].to_h do |key|
          [key, output.__send__(key)]
        end
        assert_equal({ type:, **expected }, actual)
      end
    end
  end
end
