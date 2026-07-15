# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestRegFileProperties < TestCase
      def test_property_initialization
        regfile = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_reg {
            regfile {} my_regfile;
          };
        RDL

        assert_property(regfile, :name, [:string], value: 'my_regfile')
        assert_property(regfile, :desc, [:string], value: '')
        assert_property(regfile, :alignment, [:longint])
        assert_property(regfile, :sharedextbus, [:boolean], value: false)
        assert_property(regfile, :errextbus, [:boolean], value: false)
      end

      def test_assigning_integral_value_to_supported_property_is_allowed
        template = proc do |prop_name, include_zero|
          if include_zero
            <<~RDL
              addrmap my_map {
                regfile { #{prop_name} = 0    ; reg { field { sw = r; hw = r; } a; } a; } a;
                regfile { #{prop_name} = 1    ; reg { field { sw = r; hw = r; } b; } b; } b;
                regfile { #{prop_name} = 1'd0 ; reg { field { sw = r; hw = r; } c; } c; } c;
                regfile { #{prop_name} = 1'd1 ; reg { field { sw = r; hw = r; } d; } d; } d;
                regfile { #{prop_name} = false; reg { field { sw = r; hw = r; } e; } e; } e;
                regfile { #{prop_name} = true ; reg { field { sw = r; hw = r; } f; } f; } f;
              };
            RDL
          else
            <<~RDL
              addrmap my_map {
                regfile { #{prop_name} = 1    ; reg { field { sw = r; hw = r; } a; } a; } a;
                regfile { #{prop_name} = 1'd1 ; reg { field { sw = r; hw = r; } b; } b; } b;
                regfile { #{prop_name} = true ; reg { field { sw = r; hw = r; } c; } c; } c;
              };
            RDL
          end
        end

        [:alignment].each do |prop_name|
          regfiles = evaluate(template[prop_name, false]).instances[0].instances
          assert_property_value(regfiles[0], prop_name, 1)
          assert_property_value(regfiles[1], prop_name, 1)
          assert_property_value(regfiles[2], prop_name, 1)
        end

        [:sharedextbus, :errextbus].each do |prop_name|
          regfiles = evaluate(template[prop_name, true]).instances[0].instances
          assert_property_value(regfiles[0], prop_name, false)
          assert_property_value(regfiles[1], prop_name, true)
          assert_property_value(regfiles[2], prop_name, false)
          assert_property_value(regfiles[3], prop_name, true)
          assert_property_value(regfiles[4], prop_name, false)
          assert_property_value(regfiles[5], prop_name, true)
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
                  regfile {
                    #{prop_name} = #{value};
                    reg {
                      field { sw = r; hw = r; } a;
                    } a;
                  } a;
                };
              RDL
              "#{value_type} type not supported by #{prop_name} property: expected #{expected_type}"
            )
          end
        end
      end

      def test_assigning_string_value_to_supported_property_is_allowed
        regfile = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_map {
            regfile {
              name = "foo";
              desc = "bar";
              reg {
                field { sw = r; hw = r; } a;
              } a;
            } a;
          };
        RDL
        assert_property_value(regfile, :name, 'foo')
        assert_property_value(regfile, :desc, 'bar')
      end

      def test_assigning_string_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              regfile {
                #{prop_name} = "foo";
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
              regfile {
                #{prop_name} = #{value};
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected string"
          )
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
              regfile {
                #{prop_name} = #{value};
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected string"
          )
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
              regfile {
                #{prop_name} = #{value};
                reg {
                  field { sw = w; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected string"
          )
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
              regfile {
                #{prop_name} = #{value};
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected string"
          )
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
              regfile {
                #{prop_name} = #{value};
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected string"
          )
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "addressingtype type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
              regfile {
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
              regfile {
                reg {
                  field { sw = r; hw = r; } b;
                } b;
              } b;
              b->#{prop_name} = a.a.a->ored;
            };
          RDL
        end

        [:name, :desc].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected string"
          )
        end

        [:alignment].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sharedextbus, :errextbus].each do |prop_name|
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
                regfile {
                  reg {
                    field { sw = r; hw = r; } b;
                  } b;
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
                regfile {
                  reg {
                    field { sw = r; hw = r; } b;
                  } b;
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
                regfile {
                  reg {
                    field { sw = r; hw = r; } b;
                  } b;
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
                regfile {
                  reg {
                    field { sw = r; hw = r; } b;
                  } b;
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

          [:alignment].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected longint"
            )
          end

          [:sharedextbus, :errextbus].each do |prop_name|
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
