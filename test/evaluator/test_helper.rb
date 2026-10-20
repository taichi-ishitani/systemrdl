# frozen_string_literal: true

require_relative '../test_helper'

module SystemRDL
  module Evaluator
    class TestCase < Minitest::Test
      class ExpressionEvaluator < Root
        def evaluate(_instance, **optargs)
          root = RootInstance.new(self, nil, :evaluator, nil)
          @elements
            .map { |element| element.evaluate(root, **optargs) }
            .last
        end
      end

      def ifmissing
        proc do |processor, node|
          if node.type == :__test_property_assignment
            processor.process(node.children[0])
          elsif node.type == :__test_constant_expression
            elements = processor.process_all(node.children)
            ExpressionEvaluator.new(elements, node.token_range)
          end
        end
      end

      def evaluate(code, **optargs)
        ast = SystemRDL::Parser.parse(code, **optargs)
        if optargs.key?(:test)
          SystemRDL::Evaluator.evaluate(ast, ifmissing:)
        else
          SystemRDL::Evaluator.evaluate(ast)
        end
      end

      def assert_property(element, name, types, value: nil)
        property = element.property(name)
        refute_nil(property, "no such property found: #{name}")

        assert_equal(types, property.types)
        assert_equal(value, property.value.value) unless value.nil?
      end

      def refute_property(element, name)
        property = element.property(name)
        assert_nil(property)
      end

      def assert_property_value(element, name, value, **opts)
        property = element.property(name)
        if value.nil?
          assert_nil(property.value)
        else
          assert_equal(value, property.value.value)
          opts.each do |key, optvalue|
            assert_equal(optvalue, property.value.__send__(key))
          end
        end
      end

      def assert_property_reference_value(element, name, full_name)
        property = element.property(name)
        assert_equal(full_name, property.value.value.full_name)
      end

      def assert_enum_reference_value(element, name, full_name)
        property = element.property(name)
        assert_equal(full_name, property.value.value.full_name)
      end

      def assert_value(exp, act)
        assert_equal(exp, act.value)
      end

      def evaluate_value(code, **optargs)
        ast = SystemRDL::Parser.parse(code, **optargs)
        evaluator =
          if optargs.key?(:test)
            SystemRDL::Evaluator.build_evaluator(ast, ifmissing:)
          else
            SystemRDL::Evaluator.build_evaluator(ast)
          end
        evaluator.evaluate(nil)
      end

      def assert_evaluated_value(value, type, expected)
        actual = [:type, *expected.keys].to_h do |key|
          [key, value.__send__(key)]
        end
        assert_equal({ type:, **expected}, actual)
      end

      def assert_evaluates_value(type, expected, code, **optargs)
        output = evaluate_value(code, **optargs)
        assert_evaluated_value(output, type, expected)
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
