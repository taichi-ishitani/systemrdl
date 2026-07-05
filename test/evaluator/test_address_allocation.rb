# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddressAllocation < TestCase
      def addressing_test_code(addressing_mode, alignment)
        [
          <<~RDL,
            addrmap my_map {
              addressing = #{addressing_mode};
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
          <<~RDL,
            addrmap my_map {
              addressing = #{addressing_mode};
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
          <<~RDL,
            addrmap my_map {
              alignment = #{alignment};
              addressing = #{addressing_mode};
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
        ]
      end

      def test_addressing_mode_compact
        test_codes = addressing_test_code(:compact, 8)

        regs = evaluate(test_codes[0]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x04, regs[1].address)
        20.times do |i|
          assert_value(0x0C + 0x4 * i, regs[2+i].address)
        end
        assert_value(0x5c, regs[22].address)


        regs = evaluate(test_codes[1]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x10 + 0x8 * i, regs[2+i].address)
        end
        assert_value(0xB0, regs[22].address)

        regs = evaluate(test_codes[2]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x10 + 0x4 * i, regs[2+i].address)
        end
        assert_value(0x60, regs[22].address)
      end

      def test_addressing_mode_regalign
        test_codes = addressing_test_code(:regalign, 16)

        regs = evaluate(test_codes[0]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x10 + 0x4 * i, regs[2+i].address)
        end
        assert_value(0x60, regs[22].address)

        regs = evaluate(test_codes[2]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x10, regs[1].address)
        20.times do |i|
          assert_value(0x20 + 0x4 * i, regs[2+i].address)
        end
        assert_value(0x70, regs[22].address)
      end

      def test_addressing_mode_fullalign
        test_codes = addressing_test_code(:fullalign, 4)

        regs = evaluate(test_codes[0]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x80 + 0x4 * i, regs[2+i].address)
        end
        assert_value(0xD0, regs[22].address)
      end

      def test_explicit_address_assignment
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            reg some_reg { field { sw = rw; hw = r; } a; };
            some_reg a @0x0;
            some_reg b @0x4;
            some_reg c;
            some_reg d [2] @0x10;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x04, regs[1].address)
        assert_value(0x08, regs[2].address)
        assert_value(0x10, regs[3].address)
        assert_value(0x14, regs[4].address)
      end

      def test_explicit_address_stride
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            reg some_reg { field { sw = rw; hw = r; } a; };
            some_reg a[10];
            some_reg b[10] @0x100 += 0x10;
            some_reg c;
          };
        RDL

        10.times do |i|
          assert_value(0x00 + 0x04 * i, regs[i].address)
        end
        10.times do |i|
          assert_value(0x100 + 0x10 * i, regs[i+10].address)
        end
        assert_value(0x194, regs[20].address)

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            addressing = fullalign;

            reg some_reg { field { sw = rw; hw = r; } a; };
            some_reg a;
            some_reg b[4] += 0x10;
            some_reg c;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x40, regs[1].address)
        assert_value(0x50, regs[2].address)
        assert_value(0x60, regs[3].address)
        assert_value(0x70, regs[4].address)
        assert_value(0x74, regs[5].address)
      end

      def test_explicit_address_alignment
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            alignment = 4;
            reg some_reg { field { sw = rw; hw = r; } a; };
            some_reg a;
            some_reg b %= 0x10;
            some_reg c;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x10, regs[1].address)
        assert_value(0x14, regs[2].address)
      end
    end
  end
end
