# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestOperation < TestCase
      def test_unary_operation
        ['true', "2'd1", "2'd2", '1', '2'].each do |value|
          assert_evaluates_value(
            :boolean, { value: false }, "!#{value}", test: :constant_expression
          )
        end

        ['false', "2'd0", '0'].each do |value|
          assert_evaluates_value(
            :boolean, { value: true }, "!#{value}", test: :constant_expression
          )
        end

        [
          ['true', [1, 1, 0]], ['false', [0, 0, 1]], ["1'd1", [1, 1, 0]], ["1'd0", [0, 0, 1]]
        ].each do |value, result|
          assert_evaluates_value(
            :bit, { value: result[0], width: 1 }, "+#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[1], width: 1 }, "-#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[2], width: 1 }, "~#{value}", test: :constant_expression
          )
        end

        [
          ["2'd0", [0, 0, 3]], ["2'd1", [1, 3, 2]], ["2'd2", [2, 2, 1]], ["2'd3", [3, 1, 0]]
        ].each do |value, result|
          assert_evaluates_value(
            :bit, { value: result[0], width: 2 }, "+#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[1], width: 2 }, "-#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[2], width: 2 }, "~#{value}", test: :constant_expression
          )
        end

        [
          ['0x0000_0000_0000_0000', [0x0000_0000_0000_0000, 0x0000_0000_0000_0000, 0xFFFF_FFFF_FFFF_FFFF]],
          ['0x0000_0000_0000_0001', [0x0000_0000_0000_0001, 0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFE]],
          ['0x0000_0000_0000_0002', [0x0000_0000_0000_0002, 0xFFFF_FFFF_FFFF_FFFE, 0xFFFF_FFFF_FFFF_FFFD]],
          ['0x8000_0000_0000_0000', [0x8000_0000_0000_0000, 0x8000_0000_0000_0000, 0x7FFF_FFFF_FFFF_FFFF]],
          ['0xFFFF_FFFF_FFFF_FFFE', [0xFFFF_FFFF_FFFF_FFFE, 0x0000_0000_0000_0002, 0x0000_0000_0000_0001]],
          ['0xFFFF_FFFF_FFFF_FFFF', [0xFFFF_FFFF_FFFF_FFFF, 0x0000_0000_0000_0001, 0x0000_0000_0000_0000]]
        ].each do |value, result|
          assert_evaluates_value(
            :bit, { value: result[0], width: 64 }, "+#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[1], width: 64 }, "-#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[2], width: 64 }, "~#{value}", test: :constant_expression
          )
        end

        [
          ['true' , [1, 0, 1, 0, 1, 0, 0]],
          ['false', [0, 1, 0, 1, 0, 1, 1]],
          ["1'd1" , [1, 0, 1, 0, 1, 0, 0]],
          ["1'd0" , [0, 1, 0, 1, 0, 1, 1]]
        ].each do |value, result|
          assert_evaluates_value(
            :bit, { value: result[0], width: 1 }, "&#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[1], width: 1 }, "~&#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[2], width: 1 }, "|#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[3], width: 1 }, "~|#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[4], width: 1 }, "^#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[5], width: 1 }, "~^#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[6], width: 1 }, "^~#{value}", test: :constant_expression
          )
        end

        [
          ['0x0000_0000_0000_0000', [0, 1, 0, 1, 0, 1, 1]],
          ['0x0000_0000_0000_0001', [0, 1, 1, 0, 1, 0, 0]],
          ['0x0000_0000_0000_0002', [0, 1, 1, 0, 1, 0, 0]],
          ['0x8000_0000_0000_0000', [0, 1, 1, 0, 1, 0, 0]],
          ['0xFFFF_FFFF_FFFF_FFFE', [0, 1, 1, 0, 1, 0, 0]],
          ['0xFFFF_FFFF_FFFF_FFFF', [1, 0, 1, 0, 0, 1, 1]]
        ].each do |value, result|
          assert_evaluates_value(
            :bit, { value: result[0], width: 1 }, "&#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[1], width: 1 }, "~&#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[2], width: 1 }, "|#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[3], width: 1 }, "~|#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[4], width: 1 }, "^#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[5], width: 1 }, "~^#{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: result[6], width: 1 }, "^~#{value}", test: :constant_expression
          )
        end
      end

      def test_unary_operation_with_non_integral_operand
        {
          string: '"this is a string"',
          access_type: 'na', addressing_type: 'compact', on_read_type: 'rclr', on_write_type: 'woset'
        }.each do |type, value|
          ['!', '+', '-', '~', '&', '~&', '|', '~|', '^', '~^', '^~'].each do |operator|
            message = "non integral operand is given: #{type}"
            assert_raises_evaluation_error(
              "#{operator}#{value}", message, test: :constant_expression
            )
          end
        end
      end

      def test_binary_operation
        ['true', '1', "1'b1"].product(['true', '1', "1'b1"]).each do |(lhs, rhs)|
          assert_evaluates_value(
            :boolean, { value: true }, "#{lhs} && #{rhs}", test: :constant_expression
          )
        end

        ['false', '0', "1'b0"].product(['false', '0', "1'b0", 'true', '1', "1'b1"]).each do |(lhs, rhs)|
          assert_evaluates_value(
            :boolean, { value: false }, "#{lhs} && #{rhs}", test: :constant_expression
          )
        end

        ['true', '1', "1'b1"].product(['false', '0', "1'b0", 'true', '1', "1'b1"]).each do |(lhs, rhs)|
          assert_evaluates_value(
            :boolean, { value: true }, "#{lhs} || #{rhs}", test: :constant_expression
          )
        end

        ['false', '0', "1'b0"].product(['false', '0', "1'b0"]).each do |(lhs, rhs)|
          assert_evaluates_value(
            :boolean, { value: false }, "#{lhs} || #{rhs}", test: :constant_expression
          )
        end

        ['true', "1'd1", "2'd2", '1', '2'].each do |value|
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} > 1'd0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} > 0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} < 1'd0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} < 0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1'd0 < #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "0 < #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1'd0 > #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "0 > #{value}", test: :constant_expression
          )
        end

        ['false', "1'd0", '0'].each do |value|
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} > 1'd0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} > 0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} < 1'd0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} < 0", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1'd0> #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "0 > #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1'd0 < #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "0 < #{value}", test: :constant_expression
          )
        end

        ["2'd2", '2'].each do |value|
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} >= 1'd1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} >= 1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} <= 1'd1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} <= 1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1'd1 <= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1 <= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1'd1 >= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1 >= #{value}", test: :constant_expression
          )
        end

        ['true', "1'd1", '1'].each do |value|
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} >= 1'd1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} >= 1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} <= 1'd1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} <= 1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1'd1 <= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1 <= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1'd1 >= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1 >= #{value}", test: :constant_expression
          )
        end

        ['false', "1'd0", '0'].each do |value|
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} >= 1'd1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{value} >= 1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} <= 1'd1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{value} <= 1", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1'd1 <= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "1 <= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1'd1 >= #{value}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "1 >= #{value}", test: :constant_expression
          )
        end

        ['true', "1'd1", '1'].product(['true', "1'd1", '1']).each do |(lhs, rhs)|
          assert_evaluates_value(
            :boolean, { value: true }, "#{lhs} == #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{lhs} != #{rhs}", test: :constant_expression
          )
        end

        ['false', "1'd0", '0', "2'd2", '2'].product(['true', "1'd1", '1']).each do |(lhs, rhs)|
          assert_evaluates_value(
            :boolean, { value: false }, "#{lhs} == #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{lhs} != #{rhs}", test: :constant_expression
          )
        end

        [
          ['na'     , ['na'     , 'rw'      ]],
          ['rclr'   , ['rclr'   , 'rset'    ]],
          ['woset'  , ['woset'  , 'woclr'   ]],
          ['compact', ['compact', 'regalign']],
          ['"foo"'  , ['"foo"'  , '"bar"'   ]]
        ].each do |lhs, rhs|
          assert_evaluates_value(
            :boolean, { value: true }, "#{lhs} == #{rhs[0]}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{lhs} != #{rhs[0]}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: false }, "#{lhs} == #{rhs[1]}", test: :constant_expression
          )
          assert_evaluates_value(
            :boolean, { value: true }, "#{lhs} != #{rhs[1]}", test: :constant_expression
          )
        end
      end
    end
  end
end
