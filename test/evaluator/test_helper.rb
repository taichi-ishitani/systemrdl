# frozen_string_literal: true

require_relative '../test_helper'

module SystemRDL
  module Evaluator
    class TestCase < Minitest::Test
      def evaluate(code, **optargs)
        ast = SystemRDL::Parser.parse(code, **optargs)
        SystemRDL::Evaluator.evaluate(ast)
      end

      def assert_property(instance, name, types, value: nil)
        property = instance.properties.find do |prop|
          prop.name == name &&
          prop.types == types &&
          prop.value == value
        end
        refute_nil(property, "no such property found: #{name}")
      end

      def evaluate_value(code, **optargs)
        ast = SystemRDL::Parser.parse(code, **optargs)
        evaluator = SystemRDL::Evaluator.build_evaluator(ast)
        evaluator.evaluate(nil)
        evaluator
      end

      def assert_evaluates_value(type, expected, code, **optargs)
        output = evaluate_value(code, **optargs)
        actual = [:type, *expected.keys].to_h do |key|
          [key, output.__send__(key)]
        end
        assert_equal({ type:, **expected }, actual)
      end

      def assert_raises_evaluation_error(code, message, **optargs)
        error = assert_raises(SystemRDL::EvaluationError) do
          evaluate(code, **optargs)
        end
        assert_equal(message, error.error_message)
      end
    end
  end
end
