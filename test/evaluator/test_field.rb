# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestField < TestCase
      def test_property_initialization
        field = evaluate(<<~'RDL').instances[0].instances[0].instances[0]
          addrmap some_reg {
            reg {
              field {} my_field;
            } my_reg;
          };
        RDL

        assert_property(field, :name, [:string], value: 'my_field')
        assert_property(field, :desc, [:string], value: '')

        # Field access properties
        assert_property(field, :hw, [:access_type], value: :rw)
        assert_property(field, :sw, [:access_type], value: :rw)

        # Hardware signal properties
        assert_property(field, :next, [:reference])
        assert_property(field, :reset, [:bit, :reference])
        assert_property(field, :resetsignal, [:reference])

        # Software access properties
        assert_property(field, :rclr, [:boolean], value: false)
        assert_property(field, :rset, [:boolean], value: false)
        assert_property(field, :onread, [:on_read_type])
        assert_property(field, :woset, [:boolean], value: false)
        assert_property(field, :woclr, [:boolean], value: false)
        assert_property(field, :onwrite, [:on_write_type])
        assert_property(field, :swwe, [:boolean, :reference], value: false)
        assert_property(field, :swwel, [:boolean, :reference], value: false)
        assert_property(field, :swmod, [:boolean], value: false)
        assert_property(field, :swacc, [:boolean], value: false)
        assert_property(field, :singlepulse, [:boolean], value: false)

        # Hardware access properties
        assert_property(field, :we, [:boolean, :reference], value: false)
        assert_property(field, :wel, [:boolean, :reference], value: false)
        assert_property(field, :anded, [:boolean], value: false)
        assert_property(field, :ored, [:boolean], value: false)
        assert_property(field, :xored, [:boolean], value: false)
        assert_property(field, :fieldwidth, [:longint])
        assert_property(field, :hwclr, [:boolean, :reference], value: false)
        assert_property(field, :hwset, [:boolean, :reference], value: false)
        assert_property(field, :hwenable, [:reference])
        assert_property(field, :hwmask, [:reference])

        # Counter properties
        # TODO

        # Interrupt properties
        # TODO

        # Miscellaneous field properties
        # TODO
        # assert_property(field, :encode)
        assert_property(field, :precedence, [:precedence_type], value: :sw)
        assert_property(field, :paritycheck, [:boolean], value: false)
      end

      def test_bit_index
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field {} a;
              field {} b[3];
              field {} c[15:8];
              field {} d[5];
            } my_reg;
          };
        RDL

        assert_value(0, fields[0].lsb)
        assert_value(0, fields[0].msb)

        assert_value(1, fields[1].lsb)
        assert_value(3, fields[1].msb)

        assert_value(8 , fields[2].lsb)
        assert_value(15, fields[2].msb)

        assert_value(16, fields[3].lsb)
        assert_value(20, fields[3].msb)
      end

      def test_fieldwidth_provides_default_bit_width
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { fieldwidth = 1; } a;
              field { fieldwidth = 2; } b;
              field { fieldwidth = 2; } c[2];
            } my_reg;
          };
        RDL

        assert_value(0, fields[0].lsb)
        assert_value(0, fields[0].msb)

        assert_value(1, fields[1].lsb)
        assert_value(2, fields[1].msb)

        assert_value(3, fields[2].lsb)
        assert_value(4, fields[2].msb)
      end

      def test_fieldwidth_forces_bit_width
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { fieldwidth = 2; } a[1];
              } my_reg;
            };
          RDL
          'bit width mismatch: instance width 1 fieldwidth property 2'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { fieldwidth = 2; } a[3];
              } my_reg;
            };
          RDL
          'bit width mismatch: instance width 3 fieldwidth property 2'
        )
      end

      def test_reset_value_within_bit_width_is_accepted
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { reset = 0; } a[2];
              field { reset = 3; } b[2];
              field { reset = 3; } c[2] = 0;
              field { reset = 0; } d[2] = 3;
              field {} e[2] = 3;
              field {} f[2] = 0;
              e->reset = 0;
              f->reset = 3;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :reset, 0)
        assert_property_value(fields[1], :reset, 3)
        assert_property_value(fields[2], :reset, 0)
        assert_property_value(fields[3], :reset, 3)
        assert_property_value(fields[4], :reset, 0)
        assert_property_value(fields[5], :reset, 3)
      end

      def test_reset_value_exceeding_bit_width_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { reset = 4; } a[2];
              } my_reg;
            };
          RDL
          'reset value out of range: value 0x4 range 0x0..0x3'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { reset = 0; } a[2] = 4;
              } my_reg;
            };
          RDL
          'reset value out of range: value 0x4 range 0x0..0x3'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field {} a[2] = 0;
                a->reset = 4;
              } my_reg;
            };
          RDL
          'reset value out of range: value 0x4 range 0x0..0x3'
        )
      end

      def test_valid_sw_hw_access_combinations
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { sw = rw; hw = rw; } a;
              field { sw = rw; hw = r ; } b;
              field { sw = rw; hw = w ; } c;
              field { sw = rw; hw = na; } d;

              field { sw = r ; hw = rw; } e;
              field { sw = r ; hw = r ; } f;
              field { sw = r ; hw = w ; } g;
              field { sw = r ; hw = na; } h;

              field { sw = w ; hw = rw; } i;
              field { sw = w ; hw = r ; } j;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :sw, :rw)
        assert_property_value(fields[0], :hw, :rw)
        assert_property_value(fields[1], :sw, :rw)
        assert_property_value(fields[1], :hw, :r )
        assert_property_value(fields[2], :sw, :rw)
        assert_property_value(fields[2], :hw, :w )
        assert_property_value(fields[3], :sw, :rw)
        assert_property_value(fields[3], :hw, :na)

        assert_property_value(fields[4], :sw, :r )
        assert_property_value(fields[4], :hw, :rw)
        assert_property_value(fields[5], :sw, :r )
        assert_property_value(fields[5], :hw, :r )
        assert_property_value(fields[6], :sw, :r )
        assert_property_value(fields[6], :hw, :w )
        assert_property_value(fields[7], :sw, :r )
        assert_property_value(fields[7], :hw, :na)

        assert_property_value(fields[8], :sw, :w )
        assert_property_value(fields[8], :hw, :rw)
        assert_property_value(fields[9], :sw, :w )
        assert_property_value(fields[9], :hw, :r )
      end

      def test_invalid_sw_hw_access_combinations
        [['w', 'w'], ['w', 'na'], ['na', 'rw'], ['na', 'r'], ['na', 'w'], ['na', 'na']].each do |(sw, hw)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = #{hw}; } a;
                } my_reg;
              };
            RDL
            "invalid sw/hw access combination: sw = #{sw} hw = #{hw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = rw; hw = #{hw}; } a;
                  a->sw = #{sw};
                } my_reg;
              };
            RDL
            "invalid sw/hw access combination: sw = #{sw} hw = #{hw}"
          )

          next if sw == 'na'

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = rw; } a;
                  a->hw = #{hw};
                } my_reg;
              };
            RDL
            "invalid sw/hw access combination: sw = #{sw} hw = #{hw}"
          )
        end
      end

      def test_onread_rclr_rset_can_be_set_individually
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { onread = rclr ; } a;
              field { onread = rset ; } b;
              field { onread = ruser; } c;
              field { rclr;           } d;
              field { rclr = true;    } e;
              field { rset;           } f;
              field { rset = true;    } g;

              field {} h;
              h->onread = rclr;
              field {} i;
              i->onread = rset;
              field {} j;
              j->onread = ruser;
              field {} k;
              k->rclr;
              field {} l;
              l->rclr = true;
              field {} m;
              m->rset;
              field {} n;
              n->rset = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :onread, :rclr)
        assert_property_value(fields[0], :rclr  , false)
        assert_property_value(fields[0], :rset  , false)

        assert_property_value(fields[1], :onread, :rset)
        assert_property_value(fields[1], :rclr  , false)
        assert_property_value(fields[1], :rset  , false)

        assert_property_value(fields[2], :onread, :ruser)
        assert_property_value(fields[2], :rclr  , false)
        assert_property_value(fields[2], :rset  , false)

        assert_property_value(fields[3], :onread, nil)
        assert_property_value(fields[3], :rclr  , true)
        assert_property_value(fields[3], :rset  , false)

        assert_property_value(fields[4], :onread, nil)
        assert_property_value(fields[4], :rclr  , true)
        assert_property_value(fields[4], :rset  , false)

        assert_property_value(fields[5], :onread, nil)
        assert_property_value(fields[5], :rclr  , false)
        assert_property_value(fields[5], :rset  , true)

        assert_property_value(fields[6], :onread, nil)
        assert_property_value(fields[6], :rclr  , false)
        assert_property_value(fields[6], :rset  , true)

        assert_property_value(fields[7], :onread, :rclr)
        assert_property_value(fields[7], :rclr  , false)
        assert_property_value(fields[7], :rset  , false)

        assert_property_value(fields[8], :onread, :rset)
        assert_property_value(fields[8], :rclr  , false)
        assert_property_value(fields[8], :rset  , false)

        assert_property_value(fields[9], :onread, :ruser)
        assert_property_value(fields[9], :rclr  , false)
        assert_property_value(fields[9], :rset  , false)

        assert_property_value(fields[10], :onread, nil)
        assert_property_value(fields[10], :rclr  , true)
        assert_property_value(fields[10], :rset  , false)

        assert_property_value(fields[11], :onread, nil)
        assert_property_value(fields[11], :rclr  , true)
        assert_property_value(fields[11], :rset  , false)

        assert_property_value(fields[12], :onread, nil)
        assert_property_value(fields[12], :rclr  , false)
        assert_property_value(fields[12], :rset  , true)

        assert_property_value(fields[13], :onread, nil)
        assert_property_value(fields[13], :rclr  , false)
        assert_property_value(fields[13], :rset  , true)
      end

      def test_onread_rclr_rset_are_mutually_exclusive
        ['rclr', 'rset', 'ruser'].each do |onread|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; rclr; } a;
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; rset; } a;
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; } a;
                  a->rclr;
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; } a;
                  a->rset;
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { rclr; } a;
                  a->onread = #{onread};
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { rset; } a;
                  a->onread = #{onread};
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )
        end

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { rclr; rset; } a;
              } my_reg;
            };
          RDL
          'onread, rclr and rset properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { rset; } a;
                a->rclr;
              } my_reg;
            };
          RDL
          'onread, rclr and rset properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { rclr; } a;
                a->rset;
              } my_reg;
            };
          RDL
          'onread, rclr and rset properties are mutually exclusive'
        )
      end

      def test_onread_requires_sw_read_access
        ['rclr', 'rset', 'ruser'].each do |onread|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; sw = w; } a;
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; } a;
                  a->sw = w;
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = w; } a;
                  a->onread = #{onread};
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          next if onread == 'ruser'

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{onread}; sw = w; } a;
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{onread}; } a;
                  a->sw = w;
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = w; } a;
                  a->#{onread};
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )
        end
      end
    end
  end
end
