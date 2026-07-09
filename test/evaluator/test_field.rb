# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestField < TestCase
      def test_property_initialization
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap some_reg {
            reg {
              field { sw = r; } my_field_0;
              field { hw = r; } my_field_1;
            } my_reg;
          };
        RDL

        assert_property(fields[0], :name, [:string], value: 'my_field_0')
        assert_property(fields[0], :desc, [:string], value: '')

        # Field access properties
        assert_property(fields[0], :hw, [:accesstype], value: :rw)
        assert_property(fields[1], :sw, [:accesstype], value: :rw)

        # Hardware signal properties
        assert_property(fields[0], :next, [:reference])
        assert_property(fields[0], :reset, [:bit, :reference])
        assert_property(fields[0], :resetsignal, [:reference])

        # Software access properties
        assert_property(fields[0], :rclr, [:boolean], value: false)
        assert_property(fields[0], :rset, [:boolean], value: false)
        assert_property(fields[0], :onread, [:onreadtype])
        assert_property(fields[0], :woset, [:boolean], value: false)
        assert_property(fields[0], :woclr, [:boolean], value: false)
        assert_property(fields[0], :onwrite, [:onwritetype])
        assert_property(fields[0], :swwe, [:boolean, :reference], value: false)
        assert_property(fields[0], :swwel, [:boolean, :reference], value: false)
        assert_property(fields[0], :swmod, [:boolean], value: false)
        assert_property(fields[0], :swacc, [:boolean], value: false)
        assert_property(fields[0], :singlepulse, [:boolean], value: false)

        # Hardware access properties
        assert_property(fields[0], :we, [:boolean, :reference], value: false)
        assert_property(fields[0], :wel, [:boolean, :reference], value: false)
        assert_property(fields[0], :anded, [:boolean], value: false)
        assert_property(fields[0], :ored, [:boolean], value: false)
        assert_property(fields[0], :xored, [:boolean], value: false)
        assert_property(fields[0], :fieldwidth, [:longint])
        assert_property(fields[0], :hwclr, [:boolean, :reference], value: false)
        assert_property(fields[0], :hwset, [:boolean, :reference], value: false)
        assert_property(fields[0], :hwenable, [:reference])
        assert_property(fields[0], :hwmask, [:reference])

        # Counter properties
        # TODO

        # Interrupt properties
        # TODO

        # Miscellaneous field properties
        # TODO
        # assert_property(field, :encode)
        assert_property(fields[0], :precedence, [:precedencetype], value: :sw)
        assert_property(fields[0], :paritycheck, [:boolean], value: false)
      end

      def test_assigning_integral_value_to_supported_property_is_allowed
        template = proc do |prop_name, include_zero|
          if include_zero
            <<~RDL
              addrmap my_map {
                reg {
                  field { hw = r; #{prop_name} = 0    ; } a;
                  field { hw = r; #{prop_name} = 1    ; } b;
                  field { hw = r; #{prop_name} = 1'd0 ; } c;
                  field { hw = r; #{prop_name} = 1'd1 ; } d;
                  field { hw = r; #{prop_name} = false; } e;
                  field { hw = r; #{prop_name} = true ; } f;
                } my_reg;
              };
            RDL
          else
            <<~RDL
              addrmap my_map {
                reg {
                  field { hw = r; #{prop_name} = 1    ; } a;
                  field { hw = r; #{prop_name} = 1'd1 ; } b;
                  field { hw = r; #{prop_name} = true ; } c;
                } my_reg;
              };
            RDL
          end
        end

        [:reset].each do |prop_name|
          fields = evaluate(template[prop_name, true]).instances[0].instances[0].instances
          assert_property_value(fields[0], prop_name, 0, width: 64)
          assert_property_value(fields[1], prop_name, 1, width: 64)
          assert_property_value(fields[2], prop_name, 0, width: 1)
          assert_property_value(fields[3], prop_name, 1, width: 1)
          assert_property_value(fields[4], prop_name, 0, width: 1)
          assert_property_value(fields[5], prop_name, 1, width: 1)
        end

        [:fieldwidth].each do |prop_name|
          fields = evaluate(template[prop_name, false]).instances[0].instances[0].instances
          assert_property_value(fields[0], prop_name, 1)
          assert_property_value(fields[1], prop_name, 1)
          assert_property_value(fields[2], prop_name, 1)
        end

        [
          :rclr, :rset, :woset, :woclr, :swwe, :swwel, :swmod, :swacc, :singlepulse,
          :we, :wel, :anded, :ored, :xored, :hwclr, :hwset, :paritycheck
        ].each do |prop_name|
          fields = evaluate(template[prop_name, true]).instances[0].instances[0].instances
          assert_property_value(fields[0], prop_name, false)
          assert_property_value(fields[1], prop_name, true)
          assert_property_value(fields[2], prop_name, false)
          assert_property_value(fields[3], prop_name, true)
          assert_property_value(fields[4], prop_name, false)
          assert_property_value(fields[5], prop_name, true)
        end
      end

      def test_assigning_integral_value_to_unsupported_property_is_rejected
        {
          name: :string, desc: :string, sw: :accesstype, hw: :accesstype,
          onread: :onreadtype, onwrite: :onwritetype, hwenable: :reference,
          hwmask: :reference, precedence: :precedencetype
        }.each do |prop_name, prop_type|
          {
            '0' => :bit, '1' => :bit, "16'd0" => :bit, "16'd1" => :bit,
            'true' => :boolean, 'false' => :boolean
          }.each do |value, value_type|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    field { #{prop_name} = #{value}; } a;
                  } my_reg;
                };
              RDL
              "#{value_type} type not supported by #{prop_name} property: expected #{prop_type}"
            )
          end

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{prop_name}; } a;
                } my_reg;
              };
            RDL
            "boolean type not supported by #{prop_name} property: expected #{prop_type}"
          )
        end
      end

      def test_bit_index
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { hw = r; } a;
              field { hw = r; } b[3];
              field { hw = r; } c[15:8];
              field { hw = r; } d[5];
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
              field { fieldwidth = 1; hw = r; } a;
              field { fieldwidth = 2; hw = r; } b;
              field { fieldwidth = 2; hw = r; } c[2];
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

      def test_bit_width_must_be_positive
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { hw = r; } a[0];
              } my_reg;
            };
          RDL
          'bit width must be positive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { hw = r; fieldwidth = 0; } a;
              } my_reg;
            };
          RDL
          'fieldwidth must be positive'
        )
      end

      def test_multidimensional_size_specification_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { hw = r; } a[1][2];
              } my_reg;
            };
          RDL
          'multidimensional size specification not allowed for field'
        )
      end

      def test_reset_value_within_bit_width_is_accepted
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { reset = 0; hw = r; } a[2];
              field { reset = 3; hw = r; } b[2];
              field { reset = 3; hw = r; } c[2] = 0;
              field { reset = 0; hw = r; } d[2] = 3;
              field { hw = r; } e[2] = 3;
              field { hw = r; } f[2] = 0;
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
                field { hw = r; } a[2] = 0;
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
              field { sw = rw; hw = rw; we; } a;
              field { sw = rw; hw = r ;     } b;
              field { sw = rw; hw = w ; we; } c;
              field { sw = rw; hw = na;     } d;

              field { sw = r ; hw = rw; } e;
              field { sw = r ; hw = r ; } f;
              field { sw = r ; hw = w ; } g;
              field { sw = r ; hw = na; } h;

              field { sw = w ; hw = rw; we; } i;
              field { sw = w ; hw = r ;     } j;
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
        [[:w, :w], [:w, :na], [:na, :rw], [:na, :r], [:na, :w], [:na, :na]].each do |(sw, hw)|
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
                  field { sw = rw; hw = #{hw}; we; } a;
                  a->sw = #{sw};
                } my_reg;
              };
            RDL
            "invalid sw/hw access combination: sw = #{sw} hw = #{hw}"
          )

          next if sw == :na

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = rw; we; } a;
                  a->hw = #{hw};
                } my_reg;
              };
            RDL
            "invalid sw/hw access combination: sw = #{sw} hw = #{hw}"
          )
        end
      end

      def test_onread_rclr_rset_can_be_set_individually
        [:rclr, :rset, :ruser].each do |onread|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { onread = #{onread}; hw = r; } a;
                field { hw = r; } b;
                b->onread = #{onread};
              } my_reg;
            };
          RDL

          assert_property_value(fields[0], :onread, onread)
          assert_property_value(fields[0], :rclr  , false)
          assert_property_value(fields[0], :rset  , false)

          assert_property_value(fields[1], :onread, onread)
          assert_property_value(fields[1], :rclr  , false)
          assert_property_value(fields[1], :rset  , false)
        end

        fields = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { rclr; hw = r;        } a;
              field { rclr = true; hw = r; } b;
              field { hw = r; } c;
              c->rclr;
              field { hw = r; } d;
              d->rclr = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :onread, nil)
        assert_property_value(fields[0], :rclr  , true)
        assert_property_value(fields[0], :rset  , false)

        assert_property_value(fields[1], :onread, nil)
        assert_property_value(fields[1], :rclr  , true)
        assert_property_value(fields[1], :rset  , false)

        assert_property_value(fields[2], :onread, nil)
        assert_property_value(fields[2], :rclr  , true)
        assert_property_value(fields[2], :rset  , false)

        assert_property_value(fields[3], :onread, nil)
        assert_property_value(fields[3], :rclr  , true)
        assert_property_value(fields[3], :rset  , false)

        fields = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { hw = r; rset;        } a;
              field { hw = r; rset = true; } b;
              field { hw = r; } c;
              c->rset;
              field { hw = r; } d;
              d->rset = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :onread, nil)
        assert_property_value(fields[0], :rclr  , false)
        assert_property_value(fields[0], :rset  , true)

        assert_property_value(fields[1], :onread, nil)
        assert_property_value(fields[1], :rclr  , false)
        assert_property_value(fields[1], :rset  , true)

        assert_property_value(fields[2], :onread, nil)
        assert_property_value(fields[2], :rclr  , false)
        assert_property_value(fields[2], :rset  , true)

        assert_property_value(fields[3], :onread, nil)
        assert_property_value(fields[3], :rclr  , false)
        assert_property_value(fields[3], :rset  , true)
      end

      def test_onread_rclr_rset_are_mutually_exclusive
        [:rclr, :rset, :ruser].each do |onread|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; rclr; hw = r; } a;
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; rset; hw = r; } a;
                } my_reg;
              };
            RDL
            'onread, rclr and rset properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; hw = r; } a;
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
                  field { onread = #{onread}; hw = r; } a;
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
                  field { rclr; hw = r; } a;
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
                  field { rset; hw = r; } a;
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
                field { rclr; rset; hw = r; } a;
              } my_reg;
            };
          RDL
          'onread, rclr and rset properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { rset; hw = r; } a;
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
                field { rclr; hw = r; } a;
                a->rset;
              } my_reg;
            };
          RDL
          'onread, rclr and rset properties are mutually exclusive'
        )
      end

      def test_onread_requires_sw_read_access
        [:rclr, :rset, :ruser].each do |onread|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; sw = w; hw = r; } a;
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onread = #{onread}; hw = r; } a;
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
                  field { sw = w; hw = r; } a;
                  a->onread = #{onread};
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          next if onread == :ruser

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{onread}; sw = w; hw = r; } a;
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{onread}; hw = r; } a;
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
                  field { sw = w; hw = r; } a;
                  a->#{onread};
                } my_reg;
              };
            RDL
            "sw read access required: onread = #{onread} sw = w"
          )
        end
      end

      def test_onwrite_woset_woclr_can_be_set_individually
        [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].each do |onwrite|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { onwrite = #{onwrite}; hw = r; } a;
                field { hw = r; } b;
                b->onwrite = #{onwrite};
              } my_reg;
            };
          RDL

          assert_property_value(fields[0], :onwrite, onwrite)
          assert_property_value(fields[0], :woset  , false)
          assert_property_value(fields[0], :woclr  , false)

          assert_property_value(fields[1], :onwrite, onwrite)
          assert_property_value(fields[1], :woset  , false)
          assert_property_value(fields[1], :woclr  , false)
        end

        fields = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { hw = r; woset;        } a;
              field { hw = r; woset = true; } b;
              field { hw = r; } c;
              c->woset;
              field { hw = r; } d;
              d->woset = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :onwrite, nil)
        assert_property_value(fields[0], :woset  , true)
        assert_property_value(fields[0], :woclr  , false)

        assert_property_value(fields[1], :onwrite, nil)
        assert_property_value(fields[1], :woset  , true)
        assert_property_value(fields[1], :woclr  , false)

        assert_property_value(fields[2], :onwrite, nil)
        assert_property_value(fields[2], :woset  , true)
        assert_property_value(fields[2], :woclr  , false)

        assert_property_value(fields[3], :onwrite, nil)
        assert_property_value(fields[3], :woset  , true)
        assert_property_value(fields[3], :woclr  , false)

        fields = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { hw = r; woclr;        } a;
              field { hw = r; woclr = true; } b;
              field { hw = r; } c;
              c->woclr;
              field { hw = r; } d;
              d->woclr = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :onwrite, nil)
        assert_property_value(fields[0], :woset  , false)
        assert_property_value(fields[0], :woclr  , true)

        assert_property_value(fields[1], :onwrite, nil)
        assert_property_value(fields[1], :woset  , false)
        assert_property_value(fields[1], :woclr  , true)

        assert_property_value(fields[2], :onwrite, nil)
        assert_property_value(fields[2], :woset  , false)
        assert_property_value(fields[2], :woclr  , true)

        assert_property_value(fields[3], :onwrite, nil)
        assert_property_value(fields[3], :woset  , false)
        assert_property_value(fields[3], :woclr  , true)
      end

      def test_onwrite_woset_woclr_are_mutually_exclusive
        [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].each do |onwrite|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onwrite = #{onwrite}; woset; hw = r; } a;
                } my_reg;
              };
            RDL
            'onwrite, woset and woclr properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onwrite = #{onwrite}; woclr; hw = r; } a;
                } my_reg;
              };
            RDL
            'onwrite, woset and woclr properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onwrite = #{onwrite}; hw = r; } a;
                  a->woset;
                } my_reg;
              };
            RDL
            'onwrite, woset and woclr properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onwrite = #{onwrite}; hw = r; } a;
                  a->woclr;
                } my_reg;
              };
            RDL
            'onwrite, woset and woclr properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { woset; hw = r; } a;
                  a->onwrite = #{onwrite};
                } my_reg;
              };
            RDL
            'onwrite, woset and woclr properties are mutually exclusive'
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { woclr; hw = r; } a;
                  a->onwrite = #{onwrite};
                } my_reg;
              };
            RDL
            'onwrite, woset and woclr properties are mutually exclusive'
          )
        end

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { woset; woclr; hw = r; } a;
              } my_reg;
            };
          RDL
          'onwrite, woset and woclr properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { woclr; hw = r; } a;
                a->woset;
              } my_reg;
            };
          RDL
          'onwrite, woset and woclr properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { woset; hw = r; } a;
                a->woclr;
              } my_reg;
            };
          RDL
          'onwrite, woset and woclr properties are mutually exclusive'
        )
      end

      def test_onwrite_requires_sw_write_access
        [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].each do |onwrite|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onwrite = #{onwrite}; sw = r; hw = r; } a;
                } my_reg;
              };
            RDL
            "sw write access required: onwrite = #{onwrite} sw = r"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { onwrite = #{onwrite}; hw = r; } a;
                  a->sw = r;
                } my_reg;
              };
            RDL
            "sw write access required: onwrite = #{onwrite} sw = r"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                  a->onwrite = #{onwrite};
                } my_reg;
              };
            RDL
            "sw write access required: onwrite = #{onwrite} sw = r"
          )

          next unless onwrite in :woset | :woclr

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{onwrite}; sw = r; hw = r; } a;
                } my_reg;
              };
            RDL
            "sw write access required: onwrite = #{onwrite} sw = r"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { #{onwrite}; hw = r; } a;
                  a->sw = r;
                } my_reg;
              };
            RDL
            "sw write access required: onwrite = #{onwrite} sw = r"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                  a->#{onwrite};
                } my_reg;
              };
            RDL
            "sw write access required: onwrite = #{onwrite} sw = r"
          )
        end
      end

      def test_swwe_swwel_can_be_set_individually
        fields = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { hw = r; swwe;         } a;
              field { hw = r; swwe = true;  } b;
              field { hw = r; swwel;        } c;
              field { hw = r; swwel = true; } d;

              field { hw = r; } e;
              e->swwe;
              field { hw = r; } f;
              f->swwe = true;
              field { hw = r; } g;
              g->swwel;
              field { hw = r; } h;
              h->swwel = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :swwe , true)
        assert_property_value(fields[0], :swwel, false)
        assert_property_value(fields[1], :swwe , true)
        assert_property_value(fields[1], :swwel, false)
        assert_property_value(fields[2], :swwe , false)
        assert_property_value(fields[2], :swwel, true)
        assert_property_value(fields[3], :swwe , false)
        assert_property_value(fields[3], :swwel, true)

        assert_property_value(fields[4], :swwe , true)
        assert_property_value(fields[4], :swwel, false)
        assert_property_value(fields[5], :swwe , true)
        assert_property_value(fields[5], :swwel, false)
        assert_property_value(fields[6], :swwe , false)
        assert_property_value(fields[6], :swwel, true)
        assert_property_value(fields[7], :swwe , false)
        assert_property_value(fields[7], :swwel, true)
      end

      def test_swwe_swwel_are_mutually_exclusive
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { swwe; swwel; hw = r; } a;
              } my_reg;
            };
          RDL
          'swwe and swwel properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { swwel; hw = r; } a;
                a->swwe;
              } my_reg;
            };
          RDL
          'swwe and swwel properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { swwe; hw = r; } a;
                a->swwel;
              } my_reg;
            };
          RDL
          'swwe and swwel properties are mutually exclusive'
        )
      end

      def test_we_wel_can_be_set_individually
        fields = evaluate(<<~RDL).instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { we;         } a;
              field { we = true;  } b;
              field { wel;        } c;
              field { wel = true; } d;

              field { sw = r; } e;
              e->we;
              field { sw = r; } f;
              f->we = true;
              field { sw = r; } g;
              g->wel;
              field { sw = r; } h;
              h->wel = true;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :we , true)
        assert_property_value(fields[0], :wel, false)
        assert_property_value(fields[1], :we , true)
        assert_property_value(fields[1], :wel, false)
        assert_property_value(fields[2], :we , false)
        assert_property_value(fields[2], :wel, true)
        assert_property_value(fields[3], :we , false)
        assert_property_value(fields[3], :wel, true)

        assert_property_value(fields[4], :we , true)
        assert_property_value(fields[4], :wel, false)
        assert_property_value(fields[5], :we , true)
        assert_property_value(fields[5], :wel, false)
        assert_property_value(fields[6], :we , false)
        assert_property_value(fields[6], :wel, true)
        assert_property_value(fields[7], :we , false)
        assert_property_value(fields[7], :wel, true)
      end

      def test_we_wel_are_mutually_exclusive
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { we; wel; } a;
              } my_reg;
            };
          RDL
          'we and wel properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { wel; } a;
                a->we;
              } my_reg;
            };
          RDL
          'we and wel properties are mutually exclusive'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { we; } a;
                a->wel;
              } my_reg;
            };
          RDL
          'we and wel properties are mutually exclusive'
        )
      end

      def test_valid_hw_writable_field
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { sw = r; hw = rw; } a;
              field { sw = r; hw = w ; } b;
            } my_reg;
          };
        RDL

        assert_property_value(fields[0], :sw , :r)
        assert_property_value(fields[0], :hw , :rw)
        assert_property_value(fields[0], :we , false)
        assert_property_value(fields[0], :wel, false)
        assert_property_value(fields[1], :sw , :r)
        assert_property_value(fields[1], :hw , :w)
        assert_property_value(fields[1], :we , false)
        assert_property_value(fields[1], :wel, false)

        [[:rw, :rw], [:rw, :w], [:w, :rw]].each do |(sw, hw)|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = #{sw}; hw = #{hw}; we;  } a;
                field { sw = #{sw}; hw = #{hw}; wel; } b;
              } my_reg;
            };
          RDL

          assert_property_value(fields[0], :sw , sw)
          assert_property_value(fields[0], :hw , hw)
          assert_property_value(fields[0], :we , true)
          assert_property_value(fields[0], :wel, false)
          assert_property_value(fields[1], :sw , sw)
          assert_property_value(fields[1], :hw , hw)
          assert_property_value(fields[1], :we , false)
          assert_property_value(fields[1], :wel, true)
        end
      end

      def test_we_wel_required_for_sw_hw_writable_field
        [[:rw, :rw], [:rw, :w], [:w, :rw]].each do |(sw, hw)|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = #{hw}; } a;
                } my_reg;
              };
            RDL
            "hw write enable required: sw = #{sw} hw = #{hw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = r; hw = #{hw}; } a;
                  a->sw = #{sw};
                } my_reg;
              };
            RDL
            "hw write enable required: sw = #{sw} hw = #{hw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = r; } a;
                  a->hw = #{hw};
                } my_reg;
              };
            RDL
            "hw write enable required: sw = #{sw} hw = #{hw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = #{hw}; we; } a;
                  a->we = false;
                } my_reg;
              };
            RDL
            "hw write enable required: sw = #{sw} hw = #{hw}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg {
                  field { sw = #{sw}; hw = #{hw}; wel; } a;
                  a->wel = false;
                } my_reg;
              };
            RDL
            "hw write enable required: sw = #{sw} hw = #{hw}"
          )
        end
      end

      def test_no_component_instances_are_allowed
        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              reg {
                field { hw=r; } a;
              } a;
            };
            addrmap b_addrmap {
              reg {
                field { hw=r; a_addrmap a; } b;
              } b;
            };
          RDL
          "addrmap instance not allowed in field"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              regfile a_regfile {
                reg {
                  field { hw=r; } a;
                } a;
              };
              reg {
                field { hw=r; a_regfile a; } b;
              } b;
            };
          RDL
          "regfile instance not allowed in field"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              reg a_reg {
                field { hw=r; } a;
              };
              reg {
                field { hw=r; a_reg a; } b;
              } b;
            };
          RDL
          "reg instance not allowed in field"
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap a_addrmap {
              reg {
                field a_field { hw=r; };
                field { hw=r; a_field a; } b;
              } a;
            };
          RDL
          "field instance not allowed in field"
        )
      end

      def test_no_component_definitions_are_allowed
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                field {
                  addrmap b_addrmap {
                    reg b_reg {
                      field b_field { hw = r; };
                    };
                  };
                  hw = r;
                } a;
              } a;
            };
          RDL
          'addrmap definition not allowed in field'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                field {
                  regfile b_regfile {
                    reg b_reg {
                      field b_field { hw = r; };
                    };
                  };
                  hw = r;
                } a;
              } a;
            };
          RDL
          'regfile definition not allowed in field'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                field {
                  reg b_reg {
                    field b_field { hw = r; };
                  };
                  hw = r;
                } a;
              } a;
            };
          RDL
          'reg definition not allowed in field'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap a_addrmap {
              reg {
                field {
                  field b_field { hw = r; };
                  hw = r;
                } a;
              } a;
            };
          RDL
          'field definition not allowed in field'
        )
      end
    end
  end
end
