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

        [
          ["3'd1", "65'd0", 1,  3],
          ["3'd1", "65'd1", 2,  3],
          ["3'd1", "65'd2", 4,  3],
          ["3'd1", "65'd3", 0,  3],
          ['1'   , "65'd0", 1, 64],
          ['1'   , "65'd1", 2, 64],
          ['1'   , "65'd2", 4, 64],
          ['1'   , "65'd3", 8, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} << #{rhs}", test: :constant_expression
          )
        end

        [
          ["3'd4", "65'd0", 4,  3],
          ["3'd4", "65'd1", 2,  3],
          ["3'd4", "65'd2", 1,  3],
          ["3'd4", "65'd3", 0,  3],
          ['4'   , "65'd0", 4, 64],
          ['4'   , "65'd1", 2, 64],
          ['4'   , "65'd2", 1, 64],
          ['4'   , "65'd3", 0, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} >> #{rhs}", test: :constant_expression
          )
        end

        [
          ["1'd0" , [0, 1, 3, 0                    , 0xFFFF_FFFF_FFFF_FFFC],  2],
          ["1'd1" , [1, 1, 2, 1                    , 0xFFFF_FFFF_FFFF_FFFD],  2],
          ["2'd2" , [2, 3, 1, 2                    , 0xFFFF_FFFF_FFFF_FFFE],  2],
          ["2'd3" , [3, 3, 0, 3                    , 0xFFFF_FFFF_FFFF_FFFF],  2],
          ["3'd4" , [0, 5, 7, 0                    , 0xFFFF_FFFF_FFFF_FFF8],  3],
          ["3'd5" , [1, 5, 6, 1                    , 0xFFFF_FFFF_FFFF_FFF9],  3],
          ["3'd6" , [2, 7, 5, 2                    , 0xFFFF_FFFF_FFFF_FFFA],  3],
          ["3'd7" , [3, 7, 4, 3                    , 0xFFFF_FFFF_FFFF_FFFB],  3],
          ['0'    , [0, 1, 3, 0xFFFF_FFFF_FFFF_FFFC, 0xFFFF_FFFF_FFFF_FFFC], 64],
          ['1'    , [1, 1, 2, 0xFFFF_FFFF_FFFF_FFFD, 0xFFFF_FFFF_FFFF_FFFD], 64],
          ['2'    , [2, 3, 1, 0xFFFF_FFFF_FFFF_FFFE, 0xFFFF_FFFF_FFFF_FFFE], 64],
          ['3'    , [3, 3, 0, 0xFFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFF], 64],
          ['4'    , [0, 5, 7, 0xFFFF_FFFF_FFFF_FFF8, 0xFFFF_FFFF_FFFF_FFF8], 64],
          ['5'    , [1, 5, 6, 0xFFFF_FFFF_FFFF_FFF9, 0xFFFF_FFFF_FFFF_FFF9], 64],
          ['6'    , [2, 7, 5, 0xFFFF_FFFF_FFFF_FFFA, 0xFFFF_FFFF_FFFF_FFFA], 64],
          ['7'    , [3, 7, 4, 0xFFFF_FFFF_FFFF_FFFB, 0xFFFF_FFFF_FFFF_FFFB], 64],
          ['false', [0, 1, 3, 0                    , 0xFFFF_FFFF_FFFF_FFFC],  2],
          ['true' , [1, 1, 2, 1                    , 0xFFFF_FFFF_FFFF_FFFD],  2]
        ].each do |rhs, results, width|
          assert_evaluates_value(
            :bit, { value: results[0], width: }, "2'd3 & #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[0], width: 64 }, "3 & #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[1], width: }, "2'd1 | #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[1], width: 64 }, "1 | #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[2], width: }, "2'd3 ^ #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[2], width: 64 }, "3 ^ #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[3], width: }, "2'd3 ^~ #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[4], width: 64 }, "3 ^~ #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[3], width: }, "2'd3 ~^ #{rhs}", test: :constant_expression
          )
          assert_evaluates_value(
            :bit, { value: results[4], width: 64 }, "3 ~^ #{rhs}", test: :constant_expression
          )
        end

        [
          ["8'd128", "1'd0",   0,  8],
          ["8'd128", "1'd1", 128,  8],
          ["8'd128", "2'd2",   0,  8],
          ['128'   , "1'd0",   0, 64],
          ['128'   , "1'd1", 128, 64],
          ['128'   , "2'd2", 256, 64],
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} * #{rhs}", test: :constant_expression
          )
        end

        [
          ["3'd6", "2'd3", 2,  3],
          ["3'd5", "2'd3", 1,  3],
          ["3'd4", "2'd3", 1,  3],
          ["2'd3", "2'd3", 1,  2],
          ["2'd2", "2'd3", 0,  2],
          ["1'd1", "2'd3", 0,  2],
          ["1'd0", "2'd3", 0,  2],
          ['6'   , "2'd3", 2, 64],
          ['5'   , "2'd3", 1, 64],
          ['4'   , "2'd3", 1, 64],
          ['3'   , "2'd3", 1, 64],
          ['2'   , "2'd3", 0, 64],
          ['1'   , "2'd3", 0, 64],
          ['0'   , "2'd3", 0, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} / #{rhs}", test: :constant_expression
          )
        end

        [
          ["3'd6", "2'd3", 0,  3],
          ["3'd5", "2'd3", 2,  3],
          ["3'd4", "2'd3", 1,  3],
          ["2'd3", "2'd3", 0,  2],
          ["2'd2", "2'd3", 2,  2],
          ["1'd1", "2'd3", 1,  2],
          ["1'd0", "2'd3", 0,  2],
          ['6'   , "2'd3", 0, 64],
          ['5'   , "2'd3", 2, 64],
          ['4'   , "2'd3", 1, 64],
          ['3'   , "2'd3", 0, 64],
          ['2'   , "2'd3", 2, 64],
          ['1'   , "2'd3", 1, 64],
          ['0'   , "2'd3", 0, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} % #{rhs}", test: :constant_expression
          )
        end

        [
          ["8'd254", "1'd0", 254,  8],
          ["8'd254", "1'd1", 255,  8],
          ["8'd254", "2'd2",   0,  8],
          ['254'   , "1'd0", 254, 64],
          ['254'   , "1'd1", 255, 64],
          ['254'   , "2'd2", 256, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} + #{rhs}", test: :constant_expression
          )
        end

        [
          ["8'd1", "1'd0", 1                    ,  8],
          ["8'd1", "1'd1", 0                    ,  8],
          ["8'd1", "2'd2", 255                  ,  8],
          ['1'   , "1'd0", 1                    , 64],
          ['1'   , "1'd1", 0                    , 64],
          ['1'   , "2'd2", 0xFFFF_FFFF_FFFF_FFFF, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} - #{rhs}", test: :constant_expression
          )
        end

        [
          ["6'd4", "65'd0",  1,  6],
          ["6'd4", "65'd1",  4,  6],
          ["6'd4", "65'd2", 16,  6],
          ["6'd4", "65'd3",  0,  6],
          ['4'   , "65'd0",  1, 64],
          ['4'   , "65'd1",  4, 64],
          ['4'   , "65'd2", 16, 64],
          ['4'   , "65'd3", 64, 64]
        ].each do |(lhs, rhs, result, width)|
          assert_evaluates_value(
            :bit, { value: result, width: }, "#{lhs} ** #{rhs}", test: :constant_expression
          )
        end
      end
    end
  end
end
