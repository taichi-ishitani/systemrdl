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

      def test_number
        code = '0'
        assert_evaluates_value(
          :longint, { value: 0, width: 64 }, code, test: :constant_expression
        )

        code = '0x45'
        assert_evaluates_value(
          :longint, { value: 0x45, width: 64 }, code, test: :constant_expression
        )

        code = "4'd1"
        assert_evaluates_value(
          :bit, { value: 1, width: 4 }, code, test: :constant_expression
        )

        code = "3'b101"
        assert_evaluates_value(
          :bit, { value: 0b101, width: 3 }, code, test: :constant_expression
        )

        code = "32'hdead_beaf"
        assert_evaluates_value(
          :bit, { value: 0xdead_beaf, width: 32 }, code, test: :constant_expression
        )
      end

      def test_bit_width_mismatch
        code = "1'b10"
        message = "value of number does not fit within the specified bit width: 1'b10"
        assert_raises_evaluation_error(code, message, test: :constant_expression)

        code = "1'd2"
        message = "value of number does not fit within the specified bit width: 1'd2"
        assert_raises_evaluation_error(code, message, test: :constant_expression)

        code = "31'hdead_beaf"
        message = "value of number does not fit within the specified bit width: 31'hdead_beaf"
        assert_raises_evaluation_error(code, message, test: :constant_expression)
      end
    end
  end
end
