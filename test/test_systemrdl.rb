# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  class TestSystemRDL < Minitest::Test
    def test_compile
      examples = Dir.chdir(File.join(__dir__, '../examples')) do |dir|
        [File.join(dir, 'gpio.rdl'), File.join(dir, 'pwm.rdl')]
      end

      gpio, pwm = SystemRDL.compile_files(*examples)

      #
      # gpio.rdl
      #
      assert_value('gpio', gpio.name)
      assert_value('GPIO', gpio.display_name)
      assert_value('Simple general purpose I/O controller', gpio.desc)

      [
        ['direction', 'Port Direction', 0x0],
        ['data_out', 'Output Data', 0x4],
        ['data_in', 'Input Data', 0x8]
      ].each_with_index do |(name, display_name, address), i|
        reg = gpio.regs[i]
        assert_value(name, reg.name)
        assert_value(display_name, reg.display_name)
        assert_value(address, reg.address)
      end

      fields = gpio.regs.flat_map(&:fields)
      [
        ['dir', '0: input, 1: output', 31, 0, :rw, :r, 0],
        ['value', '', 31, 0, :rw, :r, 0],
        ['value', 'Value sampled from the pins', 31, 0, :r, :w, nil]
      ].each_with_index do |(name, desc, msb, lsb, sw, hw, reset), i|
        field = fields[i]
        assert_value(name, field.name)
        assert_value(name, field.display_name)
        assert_value(desc, field.desc)
        assert_value(msb, field.msb)
        assert_value(lsb, field.lsb)
        assert_value(sw, field.sw)
        assert_value(hw, field.hw)
        assert_value(reset, field.reset)
      end

      #
      # pwm.rdl
      #
      assert_value('pwm', pwm.name)
      assert_value('PWM', pwm.display_name)
      assert_value('Pulse width modulation controller with four channels', pwm.desc)

      [
        ['ctrl', 'Control', 0x00],
        ['period', 'Period', 0x04],
        ['duty[0]', 'Duty Cycle', 0x10],
        ['duty[1]', 'Duty Cycle', 0x14],
        ['duty[2]', 'Duty Cycle', 0x18],
        ['duty[3]', 'Duty Cycle', 0x1c]
      ].each_with_index do |(name, display_name, address), i|
        reg = pwm.regs[i]
        assert_value(name, reg.name)
        assert_value(display_name, reg.display_name)
        assert_value(address, reg.address)
      end

      fields = pwm.regs.flat_map(&:fields)
      [
        ['enable', 'Enable the PWM output', 0, 0, :rw, :r, 0],
        ['polarity', 'Invert the output polarity', 1, 1, :rw, :r, 0],
        ['prescaler', 'Clock prescaler', 7, 4, :rw, :r, 0],
        ['value', 'PWM period in clock cycles', 15, 0, :rw, :r, 0xffff],
        ['value', 'Active cycles within the period', 15, 0, :rw, :r, 0],
        ['value', 'Active cycles within the period', 15, 0, :rw, :r, 0],
        ['value', 'Active cycles within the period', 15, 0, :rw, :r, 0],
        ['value', 'Active cycles within the period', 15, 0, :rw, :r, 0]
      ].each_with_index do |(name, desc, msb, lsb, sw, hw, reset), i|
        field = fields[i]
        assert_value(name, field.name)
        assert_value(name, field.display_name)
        assert_value(desc, field.desc)
        assert_value(msb, field.msb)
        assert_value(lsb, field.lsb)
        assert_value(sw, field.sw)
        assert_value(hw, field.hw)
        assert_value(reset, field.reset)
      end
    end

    def assert_value(expected, value)
      if !expected.nil?
        assert_equal(expected, value)
      else
        assert_nil(value)
      end
    end
  end
end
