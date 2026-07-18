# frozen_string_literal: true

require_relative '../test_helper'

module SystemRDL
  module Model
    class TestCase < Minitest::Test
      def build_model(code)
        ast = Parser.parse(code)
        root = Evaluator.evaluate(ast)
        Model.build(root)
      end

      def collect_fields(addrmap)
        addrmap.regs.flat_map { |reg| reg.fields }
      end

      def assert_value(expected, value)
        if !expected.nil?
          assert_equal(expected, value)
        else
          assert_nil(value)
        end
      end

      def assert_reference_value(full_name, value)
        assert_equal(full_name, value.full_name)
      end

      def assert_property_value(instance, name, value)
        property = instance.property(name)
        if !value.nil?
          assert_equal(value, property.value)
        else
          assert_nil(property.value)
        end
      end

      def assert_property_reference_value(instance, name, full_name)
        property = instance.property(name)
        assert_equal(full_name, property.value.full_name)
      end

      def refute_property(instance, name)
        property = instance.property(name)
        assert_nil(property)
      end
    end
  end
end
