# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestReg < TestCase
      def test_property_initialization
        reg = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_reg {
            reg {} my_reg;
          };
        RDL

        assert_property(reg, :name, [:string], value: 'my_reg')
        assert_property(reg, :desc, [:string], value: '')
        assert_property(reg, :regwidth, [:longint], value: 32)
        assert_property(reg, :accesswidth, [:longint])
        assert_property(reg, :errextbus, [:boolean], value: false)
        # todo
        # assert_property(reg, :intr)
        # assert_property(reg, :halt)
        assert_property(reg, :shared, [:boolean], value: false)
      end

      def test_implicit_bit_allocation
        ['rw', 'r', 'w'].zip(['rw', 'r', 'w']).each do |accesses|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a;
                field { sw = #{accesses[1]}; hw = r; } b;
                field { sw = #{accesses[0]}; hw = r; } c[16:16];
                field { sw = #{accesses[1]}; hw = r; } d;
              } my_reg;
            };
          RDL

          assert_value(1, fields[1].lsb)
          assert_value(1, fields[1].msb)
          assert_value(17, fields[3].lsb)
          assert_value(17, fields[3].msb)
        end
      end

      def test_overlapping_fields_are_rejected
        [
          ['rw', 'rw'], ['rw', 'r'], ['rw', 'w'], ['r', 'rw'], ['r', 'r'], ['w', 'rw'], ['w', 'w']
        ].each do |accesses|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{accesses[0]}; hw = r; } a[7:4];
                  field { sw = #{accesses[1]}; hw = r; } b[4:3];
                } my_reg;
              };
            RDL
            'overlapping fields not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{accesses[0]}; hw = r; } a[7:4];
                  field { sw = #{accesses[1]}; hw = r; } b[6:5];
                } my_reg;
              };
            RDL
            'overlapping fields not allowed'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{accesses[0]}; hw = r; } a[7:4];
                  field { sw = #{accesses[1]}; hw = r; } b[8:7];
                } my_reg;
              };
            RDL
            'overlapping fields not allowed'
          )
        end
      end

      def test_overlapping_ro_wo_fields_are_allowed
        [['r', 'w'], ['w', 'r']].each do |accesses|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a[7:4];
                field { sw = #{accesses[1]}; hw = r; } b[4:3];
              } my_reg;
            };
          RDL

          assert_value(4, fields[0].lsb);
          assert_value(7, fields[0].msb);
          assert_value(3, fields[1].lsb);
          assert_value(4, fields[1].msb);

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a[7:4];
                field { sw = #{accesses[1]}; hw = r; } b[6:5];
              } my_reg;
            };
          RDL

          assert_value(4, fields[0].lsb);
          assert_value(7, fields[0].msb);
          assert_value(5, fields[1].lsb);
          assert_value(6, fields[1].msb);

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{accesses[0]}; hw = r; } a[7:4];
                field { sw = #{accesses[1]}; hw = r; } b[8:7];
              } my_reg;
            };
          RDL

          assert_value(4, fields[0].lsb);
          assert_value(7, fields[0].msb);
          assert_value(7, fields[1].lsb);
          assert_value(8, fields[1].msb);
        end
      end

      def test_power_of_2_regwidth_is_accepted
        [8, 16, 32, 64, 128].each do |width|
          regs = evaluate(<<~RDL).instances[0].instances
            addrmap my_map {
              reg {
                regwidth = #{width};
                field { sw = rw; hw = r; } a;
              } my_reg;
            };
          RDL

          assert_property_value(regs[0], :regwidth, width)
        end
      end

      def test_non_power_of_2_regwidth_is_rejected
        [7, 9, 15, 17, 31, 33, 63, 65, 127, 129].each do |width|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a;
                } my_reg;
              };
            RDL
            "regwidth must be a power of 2: #{width}"
          )
        end
      end

      def test_field_out_of_register
        [8, 16, 32, 64, 128].each do |width|
          msb = width
          lsb = width - 1
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a[#{msb}:#{lsb}];
                } my_reg;
              };
            RDL
            "field out of register: bit position [#{msb}:#{lsb}] regwidth #{width}"
          )

          msb = width
          lsb = msb
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a[#{msb}:#{lsb}];
                } my_reg;
              };
            RDL
            "field out of register: bit position [#{msb}:#{lsb}] regwidth #{width}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  regwidth = #{width};
                  field { sw = rw; hw = r; } a[#{width - 1}:0];
                  field { sw = rw; hw = r; } b;
                } my_reg;
              };
            RDL
            "field out of register: bit position [#{msb}:#{lsb}] regwidth #{width}"
          )
        end
      end
    end
  end
end
