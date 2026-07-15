# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestRegProperties < TestCase
      def test_property_initialization
        reg = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_reg {
            reg {} my_reg;
          };
        RDL

        assert_property(reg, :name, [:string], value: 'my_reg')
        assert_property(reg, :desc, [:string], value: '')
        assert_property(reg, :regwidth, [:longint], value: 32)
        assert_property(reg, :accesswidth, [:longint], value: 32)
        assert_property(reg, :errextbus, [:boolean], value: false)
        # todo
        # assert_property(reg, :intr)
        # assert_property(reg, :halt)
        assert_property(reg, :shared, [:boolean], value: false)
      end

      def test_assigning_integral_value_to_supported_property_is_allowed
        template = proc do |prop_name, integral_only|
          if integral_only
            <<~RDL
              addrmap my_map {
                reg { #{prop_name} = 8    ; field { sw = r; hw = r; } a; } a;
                reg { #{prop_name} = 8'd16; field { sw = r; hw = r; } b; } b;
                reg { #{prop_name} = 32   ; field { sw = r; hw = r; } c; } c;
              };
            RDL
          else
            <<~RDL
              addrmap my_map {
                reg { #{prop_name} = 0    ; field { sw = r; hw = r; } a; } a;
                reg { #{prop_name} = 1    ; field { sw = r; hw = r; } b; } b;
                reg { #{prop_name} = 1'd0 ; field { sw = r; hw = r; } c; } c;
                reg { #{prop_name} = 1'd1 ; field { sw = r; hw = r; } d; } d;
                reg { #{prop_name} = false; field { sw = r; hw = r; } e; } e;
                reg { #{prop_name} = true ; field { sw = r; hw = r; } f; } f;
              };
            RDL
          end
        end

        [:regwidth, :accesswidth].each do |prop_name|
          regs = evaluate(template[prop_name, true]).instances[0].instances
          assert_property_value(regs[0], prop_name, 8)
          assert_property_value(regs[1], prop_name, 16)
          assert_property_value(regs[2], prop_name, 32)
        end

        [:errextbus, :shared].each do |prop_name|
          regs = evaluate(template[prop_name, false]).instances[0].instances
          assert_property_value(regs[0], prop_name, false)
          assert_property_value(regs[1], prop_name, true)
          assert_property_value(regs[2], prop_name, false)
          assert_property_value(regs[3], prop_name, true)
          assert_property_value(regs[4], prop_name, false)
          assert_property_value(regs[5], prop_name, true)
        end
      end

      def test_assigning_integral_value_to_unsupported_property_is_rejected
        {
          name: 'string', desc: 'string'
        }.each do |prop_name, expected_type|
          {
            '0' => :bit, '1' => :bit, "16'd0" => :bit, "16'd1" => :bit,
            'true' => :boolean, 'false' => :boolean
          }.each do |value, value_type|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  reg {
                    #{prop_name} = #{value};
                    field { sw = r; hw = r; } a;
                  } my_reg;
                };
              RDL
              "#{value_type} type not supported by #{prop_name} property: expected #{expected_type}"
            )
          end
        end
      end

      def test_assigning_string_value_to_supported_property_is_allowed
        reg = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_map {
            reg {
              name = "foo";
              desc = "bar";
              field { sw = r; hw = r; } a;
            } my_reg;
          };
        RDL
        assert_property_value(reg, :name, 'foo')
        assert_property_value(reg, :desc, 'bar')
      end

      def test_assigning_string_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              reg {
                #{prop_name} = "foo";
                field { sw = r; hw = r; } a;
              } my_reg;
            };
          RDL
        end

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected boolean"
          )
        end
      end

      def test_assigning_accesstype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rw, :wr, :r, :w, :rw1, :w1].sample
          <<~RDL
            addrmap my_map {
              reg {
                #{prop_name} = #{value};
                field { sw = r; hw = r; } a;
              } my_reg;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected string"
          )
        end

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected boolean"
          )
        end
      end

      def test_assigning_onreadtype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rclr, :rset, :ruser].sample
          <<~RDL
            addrmap my_map {
              reg {
                #{prop_name} = #{value};
                field { sw = r; hw = r; } a;
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

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected boolean"
          )
        end
      end

      def test_assigning_onwritetype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].sample
          <<~RDL
            addrmap my_map {
              reg {
                #{prop_name} = #{value};
                field { sw = w; hw = r; } a;
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

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected boolean"
          )
        end
      end

      def test_assigning_precedencetype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:hw, :sw].sample
          <<~RDL
            addrmap my_map {
              reg {
                #{prop_name} = #{value};
                field { sw = r; hw = r; } a;
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

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected boolean"
          )
        end
      end

      def test_assigning_addressingtype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:compact, :regalign, :fullalign].sample
          <<~RDL
            addrmap my_map {
              reg {
                #{prop_name} = #{value};
                field { sw = r; hw = r; } a;
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

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected boolean"
          )
        end
      end

      def test_assigning_property_reference_value_to_not_supported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              reg {
                field { sw = r; hw = r; } a;
              } a;
              reg {
                field { sw = r; hw = r; } b;
              } b;
              b->#{prop_name} = a.a->ored;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected string"
          )
        end

        [:regwidth, :accesswidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected longint"
          )
        end

        [:errextbus, :shared].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected boolean"
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
                reg {
                  field { sw = r; hw = r; } b;
                } b;
                b->#{prop_name} = a;
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
                reg {
                  field { sw = r; hw = r; } b;
                } b;
                b->#{prop_name} = a;
              };
            RDL
          when :reg
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                } a;
                reg {
                  field { sw = r; hw = r; } b;
                } b;
                b->#{prop_name} = a;
              };
            RDL
          when :field
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                } a;
                reg {
                  field { sw = r; hw = r; } b;
                } b;
                b->#{prop_name} = a.a;
              };
            RDL
          end
        end

        [:addrmap, :regfile, :reg, :field].each do |layer|
          [:name, :desc].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected string"
            )
          end

          [:regwidth, :accesswidth].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected longint"
            )
          end

          [:errextbus, :shared].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected boolean"
            )
          end
        end
      end
    end
  end
end
