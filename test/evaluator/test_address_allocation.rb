# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddressAllocation < TestCase
      def test_addressing_compact
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            addressing = compact;
            reg {
              field { sw = rw; hw = r; } a;
            } a;
            reg {
              regwidth = 64;
              accesswidth = 32;
              field { sw = rw; hw = r; } a;
            } b;
            reg {
              field { sw = rw; hw = r; } a;
            } c[20];
            reg {
              field { sw = rw; hw = r; } a;
            } d;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x04, regs[1].address)
        20.times do |i|
          assert_value(0x0C + 0x4 * i, regs[2+i].address)
        end
        assert_value(0x5c, regs[22].address)

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            addressing = compact;
            reg {
              regwidth = 64;
              field { sw = rw; hw = r; } a;
            } a;
            reg {
              regwidth = 64;
              field { sw = rw; hw = r; } a;
            } b;
            reg {
              regwidth = 64;
              field { sw = rw; hw = r; } a;
            } c[20];
            reg {
              regwidth = 64;
              field { sw = rw; hw = r; } a;
            } d;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x10 + 0x8 * i, regs[2+i].address)
        end
        assert_value(0xB0, regs[22].address)

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            alignment = 8;
            addressing = compact;
            reg {
              field { sw = rw; hw = r; } a;
            } a;
            reg {
              regwidth = 64;
              accesswidth = 32;
              field { sw = rw; hw = r; } a;
            } b;
            reg {
              field { sw = rw; hw = r; } a;
            } c[20];
            reg {
              field { sw = rw; hw = r; } a;
            } d;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x10 + 0x4 * i, regs[2+i].address)
        end
        assert_value(0x60, regs[22].address)
      end
    end
  end
end
