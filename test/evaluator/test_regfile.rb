# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestRegFile < TestCase
      def test_regfile_without_structural_component_instance_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
              } a;
            };
          RDL
          'no structural component instances within regfile'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
                name = "my regfile";
              } a;
            };
          RDL
          'no structural component instances within regfile'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
                reg my_reg {
                  field { sw = rw; hw = r; } a;
                };
              } a;
            };
          RDL
          'no structural component instances within regfile'
        )
      end

      def test_accesswidth
        regfiles = evaluate(<<~'RDL').instances[0].instances
          addrmap my_addrmap {
            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } a;
            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
            } b;
            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
              } b;
            } c;
          };
        RDL

        assert_equal(32, regfiles[0].accesswidth)
        assert_equal(64, regfiles[1].accesswidth)
        assert_equal(64, regfiles[2].accesswidth)
      end

      def test_size
        regfiles = evaluate(<<~'RDL').instances[0].instances
          addrmap my_addrmap {
            addressing = compact;

            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } a;
            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
            } b;
            regfile {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } c;
            regfile {
              reg { regwidth = 64; field { sw = rw; hw = r; } a; } a[3];
            } d;
            regfile {
              regfile {
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
              } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } e;
            regfile {
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
              } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } f;
            regfile {
              regfile {
                reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 64; field { sw = rw; hw = r; } b; } b;
              } a[3];
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } g;
            regfile {
              regfile {
                reg { regwidth = 64; field { sw = rw; hw = r; } a; } a;
                reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
              } a[3];
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b;
            } h;
            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b @0xC;
            } i;
            regfile {
              reg { regwidth = 32; field { sw = rw; hw = r; } a; } a @0xC;
              reg { regwidth = 32; field { sw = rw; hw = r; } b; } b @0x0;
            } j;
            regfile {
              reg { regwidth = 128; field { sw = r; hw = r; } a; } a @0x0;
              reg { regwidth = 32 ; field { sw = w; hw = r; } b; } b @0x4;
            } k;
          };
        RDL

        [8, 16, 12, 24, 20, 16, 52, 48, 16, 16, 16].each_with_index do |size, i|
          assert_equal(size, regfiles[i].size)
        end
      end
    end
  end
end
