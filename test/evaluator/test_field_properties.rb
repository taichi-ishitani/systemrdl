# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestFieldProperties < TestCase
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
        assert_property(fields[0], :next, [:field_reference, :property_reference])
        assert_property(fields[0], :reset, [:bit, :field_reference, :property_reference])
        assert_property(fields[0], :resetsignal, [:field_reference, :property_reference])

        # Software access properties
        assert_property(fields[0], :rclr, [:boolean], value: false)
        assert_property(fields[0], :rset, [:boolean], value: false)
        assert_property(fields[0], :onread, [:onreadtype])
        assert_property(fields[0], :woset, [:boolean], value: false)
        assert_property(fields[0], :woclr, [:boolean], value: false)
        assert_property(fields[0], :onwrite, [:onwritetype])
        assert_property(fields[0], :swwe, [:boolean, :field_reference, :property_reference], value: false)
        assert_property(fields[0], :swwel, [:boolean, :field_reference, :property_reference], value: false)
        assert_property(fields[0], :swmod, [:boolean], value: false)
        assert_property(fields[0], :swacc, [:boolean], value: false)
        assert_property(fields[0], :singlepulse, [:boolean], value: false)

        # Hardware access properties
        assert_property(fields[0], :we, [:boolean, :field_reference, :property_reference], value: false)
        assert_property(fields[0], :wel, [:boolean, :field_reference, :property_reference], value: false)
        assert_property(fields[0], :anded, [:boolean], value: false)
        assert_property(fields[0], :ored, [:boolean], value: false)
        assert_property(fields[0], :xored, [:boolean], value: false)
        assert_property(fields[0], :fieldwidth, [:longint])
        assert_property(fields[0], :hwclr, [:boolean, :field_reference, :property_reference], value: false)
        assert_property(fields[0], :hwset, [:boolean, :field_reference, :property_reference], value: false)
        assert_property(fields[0], :hwenable, [:field_reference, :property_reference])
        assert_property(fields[0], :hwmask, [:field_reference, :property_reference])

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
          name: 'string', desc: 'string', sw: 'accesstype', hw: 'accesstype',
          onread: 'onreadtype', onwrite: 'onwritetype', hwenable: 'field_reference or property_reference',
          hwmask: 'field_reference or property_reference', precedence: 'precedencetype'
        }.each do |prop_name, expected_type|
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
              "#{value_type} type not supported by #{prop_name} property: expected #{expected_type}"
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
            "boolean type not supported by #{prop_name} property: expected #{expected_type}"
          )
        end
      end

      def test_assigning_string_value_to_supported_property_is_allowed
        [:name, :desc].each do |prop_name|
          value = 'foo'
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; #{prop_name} = "#{value}"; } a;
              } my_reg;
            };
          RDL
          assert_property_value(fields[0], prop_name, value)
        end
      end

      def test_assigning_string_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; #{prop_name} = "foo"; } a;
              } my_reg;
            };
          RDL
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
          )
        end

        [:reset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
          )
        end

        [:hwenable, :hwmask].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected field_reference or property_reference"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected onwritetype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_accesstype_value_to_supported_property_is_allowed
        [:rw, :wr, :r, :w, :rw1, :w1, :na].each do |prop_value|
          if prop_value != :na
            fields = evaluate(<<~RDL).instances[0].instances[0].instances
              addrmap some_reg {
                reg {
                  field { sw = #{prop_value}; hw = r; } a;
                } my_reg;
              };
            RDL

            value = prop_value == :wr && :rw || prop_value
            assert_property_value(fields[0], :sw, value)
            assert_property_value(fields[0], :hw, :r)
          end

          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap some_reg {
              reg {
                field { sw = r; hw = #{prop_value}; } a;
              } my_reg;
            };
          RDL

          value = prop_value == :wr && :rw || prop_value
          assert_property_value(fields[0], :sw, :r)
          assert_property_value(fields[0], :hw, value)
        end
      end

      def test_assigning_accesstype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rw, :wr, :r, :w, :rw1, :w1, :na].sample
          <<~RDL
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; #{prop_name} = #{value}; } a;
              } my_reg;
            };
          RDL
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
          )
        end

        [:reset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
          )
        end

        [:hwenable, :hwmask].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected field_reference or property_reference"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected onwritetype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_onreadtype_value_to_supported_property_is_allowed
        [:rclr, :rset, :ruser].each do |prop_value|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; onread = #{prop_value}; } a;
              } my_reg;
            };
          RDL
          assert_property_value(fields[0], :onread, prop_value)
        end
      end

      def test_assigning_onreadtype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rclr, :rset, :ruser].sample
          <<~RDL
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; #{prop_name} = #{value}; } a;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected string"
          )
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
          )
        end

        [:reset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
          )
        end

        [:hwenable, :hwmask].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected field_reference or property_reference"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected onwritetype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_onwritetype_value_to_supported_property_is_allowed
        [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].each do |prop_value|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap some_reg {
              reg {
                field { sw = w; hw = r; onwrite = #{prop_value}; } a;
              } my_reg;
            };
          RDL
          assert_property_value(fields[0], :onwrite, prop_value)
        end
      end

      def test_assigning_onwritetype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].sample
          <<~RDL
            addrmap some_reg {
              reg {
                field { sw = w; hw = r; #{prop_name} = #{value}; } a;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected string"
          )
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
          )
        end

        [:reset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
          )
        end

        [:hwenable, :hwmask].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected field_reference or property_reference"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_precedencetype_value_to_supported_property_is_allowed
        [:hw, :sw].each do |prop_value|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; precedence = #{prop_value}; } a;
              } my_reg;
            };
          RDL
          assert_property_value(fields[0], :precedence, prop_value)
        end
      end

      def test_assigning_precedencetype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:hw, :sw].sample
          <<~RDL
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; #{prop_name} = #{value}; } a;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected string"
          )
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
          )
        end

        [:reset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
          )
        end

        [:hwenable, :hwmask].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected field_reference or property_reference"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected onwritetype"
          )
        end
      end

      def test_assigning_addressingtype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:compact, :regalign, :fullalign].sample
          <<~RDL
            addrmap some_reg {
              reg {
                field { sw = r; hw = r; #{prop_name} = #{value}; } a;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected string"
          )
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
          )
        end

        [:reset].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
          )
        end

        [:hwenable, :hwmask].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected field_reference or property_reference"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected onwritetype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_field_reference_value_to_supported_property_is_allowed
        [:swwe, :swwel, :we, :wel, :hwclr, :hwset, :reset, :hwenable, :hwmask, :next].each do |prop_name|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = r; hw = r; } a;
                field { sw = r; hw = r; } b;
                b->#{prop_name} = a;
              } my_reg;
            };
          RDL

          assert_property_reference_value(fields[1], prop_name, 'my_map.my_reg.a')
        end
      end

      def test_assigning_property_reference_value_to_supported_property_is_allowed
        [:swwe, :swwel, :we, :wel, :hwclr, :hwset, :reset, :hwenable, :hwmask, :next].each do |prop_name|
          fields = evaluate(<<~RDL).instances[0].instances[0].instances
            addrmap my_map {
              reg {
                field { sw = r; hw = r; } a;
                field { sw = r; hw = r; } b;
                b->#{prop_name} = a->ored;
              } my_reg;
            };
          RDL

          assert_property_reference_value(fields[1], prop_name, 'my_map.my_reg.a.ored')
        end
      end

      def test_assigning_field_reference_value_to_not_supported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              reg {
                field { sw = r; hw = r; } a;
                field { sw = r; hw = r; } b;
                b->#{prop_name} = a;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected string"
          )
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected onwritetype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "field_reference type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_property_reference_value_to_not_supported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              reg {
                field { sw = r; hw = r; } a;
                field { sw = r; hw = r; } b;
                b->#{prop_name} = a->ored;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected string"
          )
        end

        [
          :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
          :anded, :ored, :xored, :paritycheck
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:fieldwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw, :hw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected accesstype"
          )
        end

        [:onread].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected onreadtype"
          )
        end

        [:onwrite].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected onwritetype"
          )
        end

        [:precedence].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected precedencetype"
          )
        end
      end

      def test_assigning_container_reference_value_to_not_supported_property_is_rejected
        template = proc do |layer, prop_name|
          case layer
          when :addrmap
            <<~RDL
              addrmap my_map {
                addrmap {
                  reg {
                    field { sw = r; hw = r; } a;
                  } a;
                } a;
                a.a.a->#{prop_name} = a;
              };
            RDL
          when :regfile
            <<~RDL
              addrmap my_map {
                regfile {
                  reg {
                    field { sw = r; hw = r; } a;
                  } a;
                } a;
                a.a.a->#{prop_name} = a;
              };
            RDL
          when :reg
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                } a;
                a.a->#{prop_name} = a;
              };
            RDL
          end
        end

        [:addrmap, :regfile, :reg].each do |layer|
          [:name, :desc].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected string"
            )
          end

          [
            :rclr, :rset, :woset, :woclr, :swmod, :swacc, :singlepulse,
            :anded, :ored, :xored, :paritycheck
          ].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected boolean"
            )
          end

          [:swwe, :swwel, :we, :wel, :hwclr, :hwset].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected boolean, field_reference or property_reference"
            )
          end

          [:reset].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected bit, field_reference or property_reference"
            )
          end

          [:hwenable, :hwmask].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected field_reference or property_reference"
            )
          end

          [:fieldwidth].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected longint"
            )
          end

          [:sw, :hw].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected accesstype"
            )
          end

          [:onread].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected onreadtype"
            )
          end

          [:onwrite].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected onwritetype"
            )
          end

          [:precedence].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected precedencetype"
            )
          end
        end
      end
    end
  end
end
