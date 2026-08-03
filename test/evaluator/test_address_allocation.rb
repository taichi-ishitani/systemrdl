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
          <<~RDL,
            addrmap my_map {
              addressing = #{addressing_mode};
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } x;
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } y;
              } b;
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } x;
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } y;
              } c[20];
              reg {
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
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } x;
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } y;
              } b;
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } x;
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } y;
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

        test_codes = addressing_test_code(:compact, 32)

        regs = evaluate(test_codes[3]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x08, regs[1].address)
        20.times do |i|
          assert_value(0x18 + 0x10 * i, regs[2+i].address)
        end
        assert_value(0x154, regs[22].address)

        regs = evaluate(test_codes[4]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x20, regs[1].address)
        20.times do |i|
          assert_value(0x40 + 0x10 * i, regs[2+i].address)
        end
        assert_value(0x180, regs[22].address)
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

        test_codes = addressing_test_code(:regalign, 32)

        regs = evaluate(test_codes[3]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x10, regs[1].address)
        20.times do |i|
          assert_value(0x20 + 0x10 * i, regs[2+i].address)
        end
        assert_value(0x15C, regs[22].address)

        regs = evaluate(test_codes[4]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x20, regs[1].address)
        20.times do |i|
          assert_value(0x40 + 0x10 * i, regs[2+i].address)
        end
        assert_value(0x180, regs[22].address)
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

        regs = evaluate(test_codes[3]).instances[0].instances
        assert_value(0x00, regs[0].address)
        assert_value(0x10, regs[1].address)
        20.times do |i|
          assert_value(0x200 + 0x10 * i, regs[2+i].address)
        end
        assert_value(0x33C, regs[22].address)
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

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            regfile some_regfile {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            };
            some_regfile a @0x00;
            some_regfile b @0x10;
            some_regfile c;
            some_regfile d [2] @0x30;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x10, regs[1].address)
        assert_value(0x20, regs[2].address)
        assert_value(0x30, regs[3].address)
        assert_value(0x40, regs[4].address)
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
            regfile some_regfile {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            };
            some_regfile a[10];
            some_regfile b[10] @0x100 += 0x20;
            some_regfile c;
          };
        RDL

        10.times do |i|
          assert_value(0x00 + 0x10 * i, regs[i].address)
        end
        10.times do |i|
          assert_value(0x100 + 0x20 * i, regs[i+10].address)
        end
        assert_value(0x230, regs[20].address)

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

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            addressing = fullalign;

            regfile some_regfile {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            };

            some_regfile a;
            some_regfile b[4] += 0x20;
            some_regfile c;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x80, regs[1].address)
        assert_value(0xA0, regs[2].address)
        assert_value(0xC0, regs[3].address)
        assert_value(0xE0, regs[4].address)
        assert_value(0xF0, regs[5].address)
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

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            alignment = 32;

            regfile some_regfile {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            };

            some_regfile a;
            some_regfile b %= 0x40;
            some_regfile c;
          };
        RDL

        assert_value(0x00, regs[0].address)
        assert_value(0x40, regs[1].address)
        assert_value(0x60, regs[2].address)
      end

      def test_overlapping_regs_are_rejected
        reg_defines = <<~'RDL'
            reg reg_rw {
              field { sw = rw; hw = r; } a;
            };
            reg reg_rw1 {
              field { sw = rw1; hw = r; } a;
            };
            reg reg_ro {
              field { sw = r; hw = r; } a;
            };
            reg reg_wo {
              field { sw = w; hw = r; } a;
            };
            reg reg_wo1 {
              field { sw = w1; hw = r; } a;
            };
        RDL

        [:rw, :rw1, :ro, :wo, :wo1].product([:rw, :rw1, :ro, :wo, :wo1]).each do |accesses|
          next if accesses in [:ro, :wo] | [:ro, :wo1] | [:wo, :ro] | [:wo1, :ro]

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                reg_#{accesses[0]} a @0x10;
                reg_#{accesses[1]} b @0x10;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                regfile {
                  reg_#{accesses[0]} a @0x10;
                  reg_#{accesses[1]} b @0x10;
                } a;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                reg_#{accesses[0]} a[2] @0x10;
                reg_#{accesses[1]} b[2] @0x10;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                regfile {
                  reg_#{accesses[0]} a[2] @0x10;
                  reg_#{accesses[1]} b[2] @0x10;
                } a;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                reg_#{accesses[0]} a[2] @0x10 += 0x08;
                reg_#{accesses[1]} b @0x18;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                regfile {
                  reg_#{accesses[0]} a[2] @0x10 += 0x08;
                  reg_#{accesses[1]} b @0x18;
                } a;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                reg_#{accesses[0]} a[3] @0x0C;
                reg_#{accesses[1]} b @0x10;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                regfile {
                  reg_#{accesses[0]} a[3] @0x0C;
                  reg_#{accesses[1]} b @0x10;
                } a;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                reg_#{accesses[0]} a @0x10;
                reg_#{accesses[1]} b[2] @0x08 += 0x8;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                regfile {
                  reg_#{accesses[0]} a @0x10;
                  reg_#{accesses[1]} b[2] @0x08 += 0x8;
                } a;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                reg_#{accesses[0]} a @0x10;
                reg_#{accesses[1]} b[3] @0x0C;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{reg_defines}
              addrmap my_map {
                regfile {
                  reg_#{accesses[0]} a @0x10;
                  reg_#{accesses[1]} b[3] @0x0C;
                } a;
              };
            RDL
            'overlapping address ranges not allowed'
          )
        end
      end

      def test_overlapping_ro_wo_regs_are_allowed
        reg_defines = <<~'RDL'
          reg reg_ro {
            field { sw = r; hw = r; } a;
          };
          reg reg_wo {
            field { sw = w; hw = r; } a;
          };
          reg reg_wo1 {
            field { sw = w1; hw = r; } a;
          };
        RDL

        [[:ro, :wo], [:ro, :wo1], [:wo, :ro], [:wo1, :ro]].each do |accesses|
          regs = evaluate(<<~RDL).instances[0].instances
            #{reg_defines}
            addrmap my_map {
              reg_#{accesses[0]} a @0x10;
              reg_#{accesses[1]} b @0x10;
            };
          RDL

          assert_value(0x10, regs[0].address)
          assert_value(0x10, regs[1].address)

          regs = evaluate(<<~RDL).instances[0].instances
            #{reg_defines}
            addrmap my_map {
              reg_#{accesses[0]} a[2] @0x10;
              reg_#{accesses[1]} b[2] @0x10;
            };
          RDL

          assert_value(0x10, regs[0].address)
          assert_value(0x14, regs[1].address)
          assert_value(0x10, regs[2].address)
          assert_value(0x14, regs[3].address)

          regs = evaluate(<<~RDL).instances[0].instances
            #{reg_defines}
            addrmap my_map {
              reg_#{accesses[0]} a[2] @0x10 += 0x08;
              reg_#{accesses[1]} b @0x18;
            };
          RDL

          assert_value(0x10, regs[0].address)
          assert_value(0x18, regs[1].address)
          assert_value(0x18, regs[2].address)

          regs = evaluate(<<~RDL).instances[0].instances
            #{reg_defines}
            addrmap my_map {
              reg_#{accesses[0]} a[3] @0x0C;
              reg_#{accesses[1]} b @0x10;
            };
          RDL

          assert_value(0x0C, regs[0].address)
          assert_value(0x10, regs[1].address)
          assert_value(0x14, regs[2].address)
          assert_value(0x10, regs[3].address)

          regs = evaluate(<<~RDL).instances[0].instances
            #{reg_defines}
            addrmap my_map {
              reg_#{accesses[0]} a @0x10;
              reg_#{accesses[1]} b[2] @0x08 += 0x8;
            };
          RDL

          assert_value(0x10, regs[0].address)
          assert_value(0x08, regs[1].address)
          assert_value(0x10, regs[2].address)

          regs = evaluate(<<~RDL).instances[0].instances
            #{reg_defines}
            addrmap my_map {
              reg_#{accesses[0]} a @0x10;
              reg_#{accesses[1]} b[3] @0x0C;
            };
          RDL

          assert_value(0x10, regs[0].address)
          assert_value(0x0C, regs[1].address)
          assert_value(0x10, regs[2].address)
          assert_value(0x14, regs[3].address)
        end
      end

      def test_overlapping_with_regfile_is_rejected
        defines = <<~'RDL'
          reg reg_rw {
            field { sw = rw; hw = r; } a;
          };
          reg reg_ro {
            field { sw = r; hw = r; } a;
          };
          reg reg_wo {
            field { sw = w; hw = r; } a;
          };
          regfile regfile_rw {
            reg_rw a;
          };
          regfile regfile_ro {
            reg_ro a;
          };
          regfile regfile_wo {
            reg_wo a;
          };
        RDL

        ['regfile_rw', 'regfile_ro', 'regfile_wo'].product(['reg_rw', 'reg_ro', 'reg_wo', 'regfile_rw', 'regfile_ro', 'regfile_wo']) do |comps|
          assert_raises_evaluation_error(
            <<~RDL,
              #{defines}
              addrmap my_map {
                #{comps[0]} a @0x10;
                #{comps[1]} b @0x10;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{defines}
              addrmap my_map {
                #{comps[0]} a[2] @0x10;
                #{comps[1]} b[2] @0x10;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{defines}
              addrmap my_map {
                #{comps[0]} a[2] @0x10 += 0x08;
                #{comps[1]} b @0x18;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{defines}
              addrmap my_map {
                #{comps[0]} a[3] @0x0C;
                #{comps[1]} b @0x10;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{defines}
              addrmap my_map {
                #{comps[0]} a @0x10;
                #{comps[1]} b[2] @0x08 += 0x8;
              };
            RDL
            'overlapping address ranges not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              #{defines}
              addrmap my_map {
                #{comps[0]} a @0x10;
                #{comps[1]} b[3] @0x0C;
              };
            RDL
            'overlapping address ranges not allowed'
          )
        end
      end
    end
  end
end
