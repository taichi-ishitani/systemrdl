# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestRegFile < TestCase
      def test_regfile_instance_with_internal_is_allowed
        regfiles = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            regfile my_regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            };
            internal my_regfile a;
            regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            } internal b;
            internal regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            } c;
          };
        RDL

        refute(regfiles[0].external?)
        refute(regfiles[1].external?)
        refute(regfiles[2].external?)
      end

      def test_regfile_instance_with_external_is_allowed
        regfiles = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            regfile my_regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            };
            external my_regfile a;
            regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            } external b;
            external regfile {
              reg { field { sw = rw; hw = r; } a; } a;
            } c;
          };
        RDL

        assert(regfiles[0].external?)
        assert(regfiles[1].external?)
        assert(regfiles[2].external?)
      end

      def test_instances_with_internal_in_regfile_are_allowed
        insts = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap top {
            regfile {
            reg my_reg { field { sw = rw; hw = r; } a; };
            regfile my_regfile { my_reg a; };
            internal my_reg a;
            internal my_regfile b;
            } a;
          };
        RDL

        refute(insts[0].external?)
        refute(insts[1].external?)
      end

      def test_instances_with_external_in_regfile_are_allowed
        insts = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap top {
            regfile {
            reg my_reg { field { sw = rw; hw = r; } a; };
            regfile my_regfile { my_reg a; };
            external my_reg a;
            external my_regfile b;
            } a;
          };
        RDL

        assert(insts[0].external?)
        assert(insts[1].external?)
      end

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

      def test_power_of_2_alignment_is_accepted
        [1, 2, 4, 8, 16, 32].each do |alignment|
          regfile = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              regfile {
                alignment = #{alignment};
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a;
            };
          RDL

          assert_property_value(regfile, :alignment, alignment)
        end
      end

      def test_non_power_of_2_alignment_is_rejected
        [0, 3, 5, 7, 9, 15, 17, 31, 33].each do |alignment|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                regfile {
                  alignment = #{alignment};
                  reg {
                    field { sw = rw; hw = r; } a;
                  } a;
                } a;
              };
            RDL
            "alignment must be a power of 2: #{alignment}"
          )
        end
      end

      def test_inheriting_alignment
        regfile_define = <<~'RDL'
          regfile my_regfile {
            reg {
              regwidth = 32;
              field { sw = rw; hw = r; } a;
            } a;
            reg {
              regwidth = 32;
              field { sw = rw; hw = r; } b;
            } b;
          };
        RDL

        regfile = evaluate(<<~RDL).instances[0].instances[0]
          #{regfile_define}
          addrmap my_addrmap {
            alignment = 8;
            my_regfile a;
          };
        RDL

        assert_property_value(regfile, :alignment, 8)
        assert_value(0x08, regfile.instances[1].address)

        regfile = evaluate(<<~RDL).instances[0].instances[0].instances[0]
          #{regfile_define}
          addrmap my_addrmap {
            alignment = 8;
            regfile {
              my_regfile a;
            } a;
          };
        RDL

        assert_property_value(regfile, :alignment, 8)
        assert_value(0x08, regfile.instances[1].address)

        regfile = evaluate(<<~RDL).instances[0].instances[0].instances[0]
          #{regfile_define}
          addrmap my_addrmap {
            regfile {
              alignment = 8;
              my_regfile a;
            } a;
          };
        RDL

        assert_property_value(regfile, :alignment, 8)
        assert_value(0x08, regfile.instances[1].address)

        regfile = evaluate(<<~RDL).instances[0].instances[0].instances[0]
          #{regfile_define}
          addrmap my_addrmap {
            alignment = 4;
            regfile {
              alignment = 8;
              my_regfile a;
            } a;
          };
        RDL

        assert_property_value(regfile, :alignment, 8)
        assert_value(0x08, regfile.instances[1].address)
      end
    end
  end
end
