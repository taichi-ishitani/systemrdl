# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestLiteral < TestCase
      def test_boolean
        code = 'true'
        assert_evaluates_value(
          :boolean, { value: true }, code, test: :constant_expression
        )

        code = 'false'
        assert_evaluates_value(
          :boolean, { value: false }, code, test: :constant_expression
        )
      end
    end
  end
end
