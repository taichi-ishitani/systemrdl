# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL::Parser
  class TestLiteral < TestCase
    def test_boolean
      assert_parses(s(:boolean, 'true'), 'true', test: true)
      assert_parses(s(:boolean, 'false'), 'false', test: true)
    end

    def test_string
      string = '""'
      assert_parses(s(:string, string), string, test: true)

      string = '"This is a string"'
      assert_parses(s(:string, string), string, test: true)

      string = "\"This is also \na string\""
      assert_parses(s(:string, string), string, test: true)
    end

    def test_string_with_escaped_quote
      string = '"This third string contains a \\"double quote\\""'
      assert_parses(s(:string, '"This third string contains a "double quote""'), string, test: true)
    end

    def test_number
      assert_parses(s(:number, '0'), '0', test: true)
      assert_parses(s(:number, '09'), '09', test: true)
      assert_parses(s(:number, '40'), '40', test: true)

      assert_parses(s(:number, '0x45'), '0x45', test: true)
      assert_parses(s(:number, '0xab'), '0xab', test: true)
      assert_parses(s(:number, '0XAB'), '0XAB', test: true)
    end

    def test_verilog_style_number
      assert_parses(s(:verilog_number, "4'd1"), "4'd1", test: true)
      assert_parses(s(:verilog_number, "4'D1"), "4'D1", test: true)
      assert_parses(s(:verilog_number, "4'd01"), "4'd01", test: true)

      assert_parses(s(:verilog_number, "3'b101"), "3'b101", test: true)
      assert_parses(s(:verilog_number, "3'B101"), "3'B101", test: true)
      assert_parses(s(:verilog_number, "3'b001"), "3'b001", test: true)

      assert_parses(s(:verilog_number, "32'hdeadbeaf"), "32'hdeadbeaf", test: true)
      assert_parses(s(:verilog_number, "32'HDEADBEAF"), "32'HDEADBEAF", test: true)
      assert_parses(s(:verilog_number, "32'h0000beaf"), "32'h0000beaf", test: true)
    end

    def test_verilog_style_number_without_width
      assert_raises_parse_error("'d1", test: true)
      assert_raises_parse_error("'b101", test: true)
      assert_raises_parse_error("'hdeadbeaf", test: true)
    end

    def test_number_with_underscores
      assert_parses(s(:number, '4_0'), '4_0', test: true)

      assert_parses(s(:number, '0x4_5'), '0x4_5', test: true)
      assert_raises_parse_error('0x_45', test: true)

      assert_parses(s(:verilog_number, "4'd1_0"), "4'd1_0", test: true)
      assert_raises_parse_error("4'd_10", test: true)
      assert_raises_parse_error("1_0'd10", test: true)

      assert_parses(s(:verilog_number, "3'b1_01"), "3'b1_01", test: true)
      assert_raises_parse_error("3'b_101", test: true)
      assert_raises_parse_error("'1_0b101", test: true)

      assert_parses(s(:verilog_number, "16'hbe_af"), "16'hbe_af", test: true)
      assert_raises_parse_error("16'h_beaf", test: true)
      assert_raises_parse_error("1_6'hbeaf", test: true)
    end

    def test_access_type
      assert_parses(s(:access_type, 'na'), 'na', test: true)
      assert_parses(s(:access_type, 'rw'), 'rw', test: true)
      assert_parses(s(:access_type, 'wr'), 'wr', test: true)
      assert_parses(s(:access_type, 'rw1'), 'rw1', test: true)
      assert_parses(s(:access_type, 'r'), 'r', test: true)
      assert_parses(s(:access_type, 'w'), 'w', test: true)
      assert_parses(s(:access_type, 'w1'), 'w1', test: true)
    end

    def test_on_read_type
      assert_parses(s(:on_read_type, 'rclr'), 'rclr', test: true)
      assert_parses(s(:on_read_type, 'rset'), 'rset', test: true)
      assert_parses(s(:on_read_type, 'ruser'), 'ruser', test: true)
    end

    def test_on_write_type
      assert_parses(s(:on_write_type, 'woset'), 'woset', test: true)
      assert_parses(s(:on_write_type, 'woclr'), 'woclr', test: true)
      assert_parses(s(:on_write_type, 'wot'), 'wot', test: true)
      assert_parses(s(:on_write_type, 'wzs'), 'wzs', test: true)
      assert_parses(s(:on_write_type, 'wzc'), 'wzc', test: true)
      assert_parses(s(:on_write_type, 'wzt'), 'wzt', test: true)
      assert_parses(s(:on_write_type, 'wset'), 'wset', test: true)
      assert_parses(s(:on_write_type, 'wclr'), 'wclr', test: true)
      assert_parses(s(:on_write_type, 'wuser'), 'wuser', test: true)
    end

    def test_addressing_type
      assert_parses(s(:addressing_type, 'compact'), 'compact', test: true)
      assert_parses(s(:addressing_type, 'regalign'), 'regalign', test: true)
      assert_parses(s(:addressing_type, 'fullalign'), 'fullalign', test: true)
    end

    def test_precedence_type
      assert_parses(s(:precedence_type, 'hw'), 'hw', test: true)
      assert_parses(s(:precedence_type, 'sw'), 'sw', test: true)
    end
  end
end
