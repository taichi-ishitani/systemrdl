# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestMem < TestCase
      def test_mem_instance_without_inst_type_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              mem my_mem {
                regwidth = 32;
              };
              my_mem a;
            };
          RDL
          'mem instance without instance type not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              mem {
                regwidth = 32;
              } a;
            };
          RDL
          'mem instance without instance type not allowed'
        )
      end

      def test_mem_instance_with_internal_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              mem my_mem { regwidth = 32; };
              internal my_mem a;
            };
          RDL
          'mem instance with internal not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              mem { regwidth = 32; } internal a;
            };
          RDL
          'mem instance with internal not allowed'
        )


        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap top {
              internal mem { regwidth = 32; } a;
            };
          RDL
          'mem instance with internal not allowed'
        )
      end

      def test_mem_instance_with_external_is_allowed
        mems = evaluate(<<~'RDL').instances[0].instances
          addrmap top {
            mem my_mem { memwidth = 32; };
            external my_mem a;
            mem { memwidth = 32; } external b;
            external mem { memwidth = 32; } c;
          };
        RDL

        assert(mems[0].external)
        assert(mems[1].external)
        assert(mems[2].external)
      end

      def test_accesswidth
        [
          [1, 8], [8, 8], [9, 16], [15, 16], [17, 32], [32, 32],
          [33, 64], [63, 64]
        ].each do |(memwidth, accesswidth)|
          mem = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              external mem {
                memwidth = #{memwidth};
              } a;
            };
          RDL

          assert_equal(accesswidth, mem.accesswidth)
        end

        mem = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_map {
            external mem {
              field my_field { sw = rw; hw = r; };
              reg { regwidth = 16; my_field a; } a;
              reg { regwidth = 64; accesswidth = 32; my_field a; } c;
              mementries = 2;
            } a;
          };
        RDL

        assert_equal(32, mem.accesswidth)
      end

      def test_size
        [1, 2, 3, 4].product([8, 16, 32, 64]).each do |mementries, memwidth|
          mem = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              external mem {
                mementries = #{mementries};
                memwidth = #{memwidth};
              } a;
            };
          RDL

          size = mementries * memwidth / 8;
          assert_equal(size, mem.size)
        end
      end

      def test_inheriting_alignment
        regs = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            external mem {
              reg my_reg {
                regwidth = 32;
                field { sw = rw; hw = r; } a;
              };
              my_reg a;
              my_reg b;
              mementries = 4;
            } a;
            alignment = 8;
          };
        RDL

        assert_value(0x8, regs[1].address)
      end

      def test_inheriting_addressing
        template = proc do |addressing|
          <<~RDL
            addrmap my_map {
              addressing = #{addressing};
              external mem {
                reg {
                  regwidth = 32;
                  accesswidth = 32;
                  field { sw = rw; hw = r; } a;
                } a;
                reg {
                  regwidth = 64;
                  accesswidth = 32;
                  field { sw = rw; hw = r; } a;
                } b[2];
                mementries = 8;
              } a;
            };
          RDL
        end

        regs = evaluate(template[:compact]).instances[0].instances[0].instances
        assert_value(0x04, regs[1].address)

        regs = evaluate(template[:regalign]).instances[0].instances[0].instances
        assert_value(0x08, regs[1].address)

        regs = evaluate(template[:fullalign]).instances[0].instances[0].instances
        assert_value(0x10, regs[1].address)
      end

      def test_positive_mementries_is_accepted
        [1, 7, 8, 15, 16, 17, 31, 32, 33].each do |mementries|
          mem = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              external mem { mementries = #{mementries}; memwidth = 32; } a;
            };
          RDL

          assert_property_value(mem, :mementries, mementries)
        end
      end

      def test_non_positive_mementries_is_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              external mem { mementries = 0; memwidth = 32; } a;
            };
          RDL
          'mementries must be positive'
        )
      end

      def test_positive_memwidth_is_accepted
        [1, 7, 8, 15, 16, 17, 31, 32, 33].each do |memwidth|
          mem = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              external mem { memwidth = #{memwidth}; } a;
            };
          RDL

          assert_property_value(mem, :memwidth, memwidth)
        end
      end

      def test_non_positive_memwidth_is_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              external mem { memwidth = 0; } a;
            };
          RDL
          'memwidth must be positive'
        )
      end

      def test_omitting_memwidth_without_virtual_regs_is_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              external mem {} a;
            } a;
          RDL
          'omitting memwidth without virtual regs not allowed'
        )
      end

      def test_regwidth_within_entrywidth_is_allowed
        [17, 31, 32].each do |memwidth|
          mem = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              external mem {
                memwidth = #{memwidth};
                reg { regwidth = 32; field { sw = rw; hw = r;} a; } a;
              } a;
            };
          RDL

          assert_property_value(mem, :memwidth, memwidth)

          reg = mem.instances[0]
          assert_property_value(reg, :regwidth, 32)
        end
      end

      def test_regwidth_larger_than_entrywidth_is_rejected
        [
          [1, 8, 16], [7, 8, 16], [8, 8, 16],
          [9, 16, 32], [15, 16, 32], [16, 16, 32],
          [17, 32, 64], [31, 32, 64], [32, 32, 64]
        ].each do |(memwidth, entrywidth, regwidth)|
          message =
            'regwidth larger than entry width not allowed: ' \
            "entry width #{entrywidth} (memwidth #{memwidth}) regwidth #{regwidth}"
          assert_raises_evaluation_error(
            <<~RDL, message
              addrmap my_map {
                external mem {
                  memwidth = #{memwidth};
                  reg {
                    regwidth = #{regwidth};
                    field { sw = rw; hw = r; } a;
                  } a;
                } a;
              };
            RDL
          )
        end
      end

      def test_virtual_reg_outside_mem_area_is_rejected
        reg_define = <<~RDL
          reg my_reg {
            regwidth = 64;
            accesswidth = 32;
            field { sw = rw; hw = r; } a;
          };
        RDL

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              #{reg_define}
              external mem {
                mementries = 2;
                memwidth = 64;
                my_reg a @0x10;
              } a;
            };
          RDL
          'virtual reg outside mem area not allowed: mem size 16 reg address 0x10 reg size 8'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              #{reg_define}
              external mem {
                mementries = 2;
                memwidth = 64;
                my_reg a @0xC;
              } a;
            };
          RDL
          'virtual reg outside mem area not allowed: mem size 16 reg address 0xc reg size 8'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              #{reg_define}
              external mem {
                mementries = 2;
                memwidth = 64;
                my_reg a [3];
              } a;
            };
          RDL
          'virtual reg outside mem area not allowed: mem size 16 reg address 0x10 reg size 8'
        )
      end

      def test_virtual_field_outside_memwidth_is_rejected
        [[31, 30], [25, 24], [24, 23]].each do |(msb, lsb)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                external mem {
                  memwidth = 24;
                  reg {
                    regwidth = 32;
                    field { sw = rw; hw = r; } a[1:0];
                    field { sw = rw; hw = r; } b[#{msb}:#{lsb}];
                  } a;
                } a;
              };
            RDL
            "virtual field outside memwidth not allowed: memwidth 24 msb #{msb} lsb #{lsb}"
          )
        end
      end

      def test_mismatch_between_mem_sw_and_virtual_field_sw_is_rejected
        [:rw, :r, :w, :rw1, :w1].product([:rw, :r, :w, :rw1, :w1]).each do |mem_sw, field_sw|
          next if mem_sw == field_sw

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                external mem {
                  sw = #{mem_sw};
                  reg {
                    field { sw = #{field_sw}; hw = r; } a;
                  } a;
                } a;
              };
            RDL
            "mismatch between mem sw and virtual field sw: mem #{mem_sw} virtual field #{field_sw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                external mem {
                  sw = #{mem_sw};
                  reg {
                    field { sw = #{mem_sw}; hw = r; } a;
                  } a;
                } a;
                a.a.a->sw = #{field_sw};
              };
            RDL
            "mismatch between mem sw and virtual field sw: mem #{mem_sw} virtual field #{field_sw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                external mem {
                  sw = #{field_sw};
                  reg {
                    field { sw = #{field_sw}; hw = r; } a;
                  } a;
                } a;
                a->sw = #{mem_sw};
              };
            RDL
            "mismatch between mem sw and virtual field sw: mem #{mem_sw} virtual field #{field_sw}"
          )
        end
      end

      def test_instances_with_internal_in_regfile_are_allowed
        insts = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap top {
            external mem {
              internal reg { field { sw = rw; hw = r; } a; } a;
            } a;
          };
        RDL

        refute(insts[0].external)
      end

      def test_instances_with_external_in_regfile_are_allowed
        insts = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap top {
            external mem {
              external reg { field { sw = rw; hw = r; } a; } a;
            } a;
          };
        RDL

        assert(insts[0].external)
      end

      def test_addrmap_regfile_mem_instances_are_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap top {
              addrmap my_map {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              };
              external mem { my_map b; } b;
            };
          RDL
          "addrmap instance not allowed in mem"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap top {
              regfile my_regfile {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              };
              external mem { my_regfile b; } b;
            };
          RDL
          "regfile instance not allowed in mem"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap top {
              mem my_mem { memwidth = 32; };
              external mem { external my_mem b; } b;
            };
          RDL
          "mem instance not allowed in mem"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap top {
              field my_field { sw = rw; hw = r; };
              external mem { my_field b; } b;
            };
          RDL
          "field instance not allowed in mem"
        )
      end

      def test_reg_field_definitions_are_allowed
        mem = evaluate(<<~RDL).instances[0].instances[0]
          addrmap top {
            external mem {
              field my_field { sw = rw; hw = r; };
              reg my_reg { my_field a; };
              my_reg b;
            } c;
          };
        RDL

        reg = mem.instances[0]
        assert_property_value(reg, :name, 'b')

        field = reg.instances[0]
        assert_property_value(field, :name, 'a')
      end

      def test_addrmap_regfile_mem_definitions_are_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              external mem {
                addrmap b_addrmap {
                  reg b_reg {
                    field b_field { hw = r; };
                  };
                };
              } a;
            };
          RDL
          'addrmap definition not allowed in mem'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              external mem {
                regfile b_regfile {
                  reg b_reg {
                    field b_field { hw = r; };
                  };
                };
              } a;
            };
          RDL
          'regfile definition not allowed in mem'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              external mem {
                mem b_mem { memwidth = 32; };
              } a;
            };
          RDL
          'mem definition not allowed in mem'
        )
      end
    end
  end
end
