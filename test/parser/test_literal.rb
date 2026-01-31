# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL::Parser
  class TestLiteral < TestCase
    def test_boolean
      assert_parses_expression(s(:boolean, 'true'), 'true')
      assert_parses_expression(s(:boolean, 'false'), 'false')
    end

    def test_string
      string = '""'
      assert_parses_expression(s(:string, string), string)

      string = '"This is a string"'
      assert_parses_expression(s(:string, string), string)

      string = "\"This is also \na string\""
      assert_parses_expression(s(:string, string), string)
    end

    def test_string_with_escaped_quote
      string = '"This third string contains a \\"double quote\\""'
      assert_parses_expression(s(:string, '"This third string contains a "double quote""'), string)
    end

    def test_number
      assert_parses_expression(s(:number, '0'), '0')
      assert_parses_expression(s(:number, '09'), '09')
      assert_parses_expression(s(:number, '40'), '40')

      assert_parses_expression(s(:number, '0x45'), '0x45')
      assert_parses_expression(s(:number, '0xab'), '0xab')
      assert_parses_expression(s(:number, '0XAB'), '0XAB')
    end

    def test_verilog_style_number
      assert_parses_expression(s(:verilog_number, "4'd1"), "4'd1")
      assert_parses_expression(s(:verilog_number, "4'D1"), "4'D1")
      assert_parses_expression(s(:verilog_number, "4'd01"), "4'd01")

      assert_parses_expression(s(:verilog_number, "3'b101"), "3'b101")
      assert_parses_expression(s(:verilog_number, "3'B101"), "3'B101")
      assert_parses_expression(s(:verilog_number, "3'b001"), "3'b001")

      assert_parses_expression(s(:verilog_number, "32'hdeadbeaf"), "32'hdeadbeaf")
      assert_parses_expression(s(:verilog_number, "32'HDEADBEAF"), "32'HDEADBEAF")
      assert_parses_expression(s(:verilog_number, "32'h0000beaf"), "32'h0000beaf")
    end

    def test_verilog_style_number_without_width
      assert_raises_parse_error("'d1", test: :constant_expression)
      assert_raises_parse_error("'b101", test: :constant_expression)
      assert_raises_parse_error("'hdeadbeaf", test: :constant_expression)
    end

    def test_number_with_underscores
      assert_parses_expression(s(:number, '4_0'), '4_0')

      assert_parses_expression(s(:number, '0x4_5'), '0x4_5')
      assert_raises_parse_error('0x_45', test: :constant_expression)

      assert_parses_expression(s(:verilog_number, "4'd1_0"), "4'd1_0")
      assert_raises_parse_error("4'd_10", test: :constant_expression)
      assert_raises_parse_error("1_0'd10", test: :constant_expression)

      assert_parses_expression(s(:verilog_number, "3'b1_01"), "3'b1_01")
      assert_raises_parse_error("3'b_101", test: :constant_expression)
      assert_raises_parse_error("'1_0b101", test: :constant_expression)

      assert_parses_expression(s(:verilog_number, "16'hbe_af"), "16'hbe_af")
      assert_raises_parse_error("16'h_beaf", test: :constant_expression)
      assert_raises_parse_error("1_6'hbeaf", test: :constant_expression)
    end

    def test_access_type
      assert_parses_expression(s(:access_type, 'na'), 'na')
      assert_parses_expression(s(:access_type, 'rw'), 'rw')
      assert_parses_expression(s(:access_type, 'wr'), 'wr')
      assert_parses_expression(s(:access_type, 'rw1'), 'rw1')
      assert_parses_expression(s(:access_type, 'r'), 'r')
      assert_parses_expression(s(:access_type, 'w'), 'w')
      assert_parses_expression(s(:access_type, 'w1'), 'w1')
    end

    def test_on_read_type
      assert_parses_expression(s(:on_read_type, 'rclr'), 'rclr')
      assert_parses_expression(s(:on_read_type, 'rset'), 'rset')
      assert_parses_expression(s(:on_read_type, 'ruser'), 'ruser')
    end

    def test_on_write_type
      assert_parses_expression(s(:on_write_type, 'woset'), 'woset')
      assert_parses_expression(s(:on_write_type, 'woclr'), 'woclr')
      assert_parses_expression(s(:on_write_type, 'wot'), 'wot')
      assert_parses_expression(s(:on_write_type, 'wzs'), 'wzs')
      assert_parses_expression(s(:on_write_type, 'wzc'), 'wzc')
      assert_parses_expression(s(:on_write_type, 'wzt'), 'wzt')
      assert_parses_expression(s(:on_write_type, 'wset'), 'wset')
      assert_parses_expression(s(:on_write_type, 'wclr'), 'wclr')
      assert_parses_expression(s(:on_write_type, 'wuser'), 'wuser')
    end

    def test_addressing_type
      assert_parses_expression(s(:addressing_type, 'compact'), 'compact')
      assert_parses_expression(s(:addressing_type, 'regalign'), 'regalign')
      assert_parses_expression(s(:addressing_type, 'fullalign'), 'fullalign')
    end
  end
end
