# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestLiteral < TestCase
      def test_boolean
        code = 'true'
        assert_evaluates_value(
          { kind: :boolean }, true, code, test: :constant_expression
        )

        code = 'false'
        assert_evaluates_value(
          { kind: :boolean }, false, code, test: :constant_expression
        )
      end

      def test_number
        code = '0'
        assert_evaluates_value(
          { kind: :bit, width: 64 }, 0, code, test: :constant_expression
        )

        code = '0x45'
        assert_evaluates_value(
          { kind: :bit, width: 64 }, 0x45, code, test: :constant_expression
        )

        code = "4'd1"
        assert_evaluates_value(
          { kind: :bit, width: 4 }, 1, code, test: :constant_expression
        )

        code = "3'b101"
        assert_evaluates_value(
          { kind: :bit, width: 3 }, 0b101, code, test: :constant_expression
        )

        code = "32'hdead_beaf"
        assert_evaluates_value(
          { kind: :bit, width: 32 }, 0xdead_beaf, code, test: :constant_expression
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

      def test_string
        code = '"This is a string"'
        assert_evaluates_value(
          { kind: :string }, 'This is a string', code, test: :constant_expression
        )
      end

      def test_accesstype
        code = 'na'
        assert_evaluates_value(
          { kind: :accesstype }, :na, code, test: :constant_expression
        )

        code = 'rw'
        assert_evaluates_value(
          { kind: :accesstype }, :rw, code, test: :constant_expression
        )

        code = 'wr'
        assert_evaluates_value(
          { kind: :accesstype }, :rw, code, test: :constant_expression
        )

        code = 'r'
        assert_evaluates_value(
          { kind: :accesstype }, :r, code, test: :constant_expression
        )

        code = 'w'
        assert_evaluates_value(
          { kind: :accesstype }, :w, code, test: :constant_expression
        )

        code = 'rw1'
        assert_evaluates_value(
          { kind: :accesstype }, :rw1, code, test: :constant_expression
        )

        code = 'w1'
        assert_evaluates_value(
          { kind: :accesstype }, :w1, code, test: :constant_expression
        )
      end

      def test_onreadtype
        code = 'rclr'
        assert_evaluates_value(
          { kind: :onreadtype }, :rclr, code, test: :constant_expression
        )

        code = 'rset'
        assert_evaluates_value(
          { kind: :onreadtype }, :rset, code, test: :constant_expression
        )

        code = 'ruser'
        assert_evaluates_value(
          { kind: :onreadtype }, :ruser, code, test: :constant_expression
        )
      end

      def test_onwritetype
        code = 'woset'
        assert_evaluates_value(
          { kind: :onwritetype }, :woset , code, test: :constant_expression
        )

        code = 'woclr'
        assert_evaluates_value(
          { kind: :onwritetype }, :woclr, code, test: :constant_expression
        )

        code = 'wot'
        assert_evaluates_value(
          { kind: :onwritetype }, :wot, code, test: :constant_expression
        )

        code = 'wzs'
        assert_evaluates_value(
          { kind: :onwritetype }, :wzs, code, test: :constant_expression
        )

        code = 'wzc'
        assert_evaluates_value(
          { kind: :onwritetype }, :wzc, code, test: :constant_expression
        )

        code = 'wzt'
        assert_evaluates_value(
          { kind: :onwritetype }, :wzt, code, test: :constant_expression
        )

        code = 'wclr'
        assert_evaluates_value(
          { kind: :onwritetype }, :wclr, code, test: :constant_expression
        )

        code = 'wset'
        assert_evaluates_value(
          { kind: :onwritetype }, :wset, code, test: :constant_expression
        )

        code = 'wuser'
        assert_evaluates_value(
          { kind: :onwritetype }, :wuser, code, test: :constant_expression
        )
      end

      def test_addressingtype
        code = 'compact'
        assert_evaluates_value(
          { kind: :addressingtype }, :compact, code, test: :constant_expression
        )

        code = 'regalign'
        assert_evaluates_value(
          { kind: :addressingtype }, :regalign, code, test: :constant_expression
        )

        code = 'fullalign'
        assert_evaluates_value(
          { kind: :addressingtype }, :fullalign, code, test: :constant_expression
        )
      end
    end
  end
end
