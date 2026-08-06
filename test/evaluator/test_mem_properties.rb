# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestMemProperties < TestCase
      def test_property_initialization
        mem = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap some_mem {
            external mem {
              reg { field { sw = rw; hw = r; } a; } a;
            } my_mem;
          };
        RDL

        assert_property(mem, :name, [:string], value: 'my_mem')
        assert_property(mem, :desc, [:string], value: '')
        assert_property(mem, :mementries, [:longint], value: 1)
        assert_property(mem, :memwidth, [:longint], value: 32)
        assert_property(mem, :sw, [:accesstype], value: :rw)
      end

      def test_no_sw_related_properties_exist
        field = evaluate(<<~'RDL').instances[0].instances[0].instances[0].instances[0]
          addrmap some_mem {
            external mem {
              reg { field { sw = rw; hw = r; } a; } a;
            } my_mem;
          };
        RDL

        refute_property(field, :rclr)
        refute_property(field, :rset)
        refute_property(field, :onread)
        refute_property(field, :woset)
        refute_property(field, :woclr)
        refute_property(field, :onwrite)
        refute_property(field, :swwe)
        refute_property(field, :swwel)
        refute_property(field, :swmod)
        refute_property(field, :swacc)
        refute_property(field, :singlepulse)
      end

      def test_default_memwidth
        mem = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_map {
            external mem {
              field my_field { sw = rw; hw = r; };
              reg { regwidth = 16; my_field a; } a;
              reg { regwidth = 32; my_field b; } b;
              reg { regwidth = 64; my_field a; } c;
              mementries = 4;
            } a;
          };
        RDL

        assert_property_value(mem, :memwidth, 64)
      end

      def test_assigning_integral_value_to_supported_property_is_allowed
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              reg my_reg { regwidth = 8; field { sw = rw; hw = r; } f; };
              external mem { #{prop_name} = 1    ; my_reg a; } a;
              external mem { #{prop_name} = 1'd1 ; my_reg b; } b;
              external mem { #{prop_name} = true ; my_reg c; } c;
            };
          RDL
        end

        [:mementries, :memwidth].each do |prop_name|
          mems = evaluate(template[prop_name]).instances[0].instances
          assert_property_value(mems[0], prop_name, 1)
          assert_property_value(mems[1], prop_name, 1)
          assert_property_value(mems[2], prop_name, 1)
        end
      end

      def test_assigning_integral_value_to_unsupported_property_is_rejected
        {
          name: 'string', desc: 'string', sw: 'accesstype'
        }.each do |prop_name, expected_type|
          {
            '0' => :bit, '1' => :bit, "16'd0" => :bit, "16'd1" => :bit,
            'true' => :boolean, 'false' => :boolean
          }.each do |value, value_type|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  external mem {
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
        mem = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_map {
            external mem {
              name = "foo";
              desc = "bar";
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            } a;
          };
        RDL
        assert_property_value(mem, :name, 'foo')
        assert_property_value(mem, :desc, 'bar')
      end

      def test_assigning_string_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              external mem {
                #{prop_name} = "foo";
                reg {
                  field { sw = r; hw = r; } a;
                } a;
              } a;
            };
          RDL
        end

        [:mementries, :memwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected accesstype"
          )
        end
      end

      def test_assigning_accesstype_value_to_supported_property_is_allowed
        mem = evaluate(<<~RDL).instances[0].instances[0]
          addrmap my_map {
            external mem {
              sw = r;
              reg {
                field { sw = r; hw = r; } a;
              } a;
            } a;
          };
        RDL
        assert_property_value(mem, :sw, :r)
      end

      def test_assigning_accesstype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rw, :wr, :r, :w, :rw1, :w1].sample
          <<~RDL
            addrmap my_map {
              external mem {
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

        [:mementries, :memwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected longint"
          )
        end
      end

      def run_property_assignment_test_with_unsupported_type(proop_type, input_values)
        template = proc do |prop_name|
          value = input_values.sample
          <<~RDL
            addrmap my_map {
              external mem {
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
            "#{proop_type} type not supported by #{prop_name} property: expected string"
          )
        end

        [:mementries, :memwidth].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "#{proop_type} type not supported by #{prop_name} property: expected longint"
          )
        end

        [:sw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "#{proop_type} type not supported by #{prop_name} property: expected accesstype"
          )
        end
      end

      def test_assigning_onreadtype_value_to_unsupported_property_is_rejected
        run_property_assignment_test_with_unsupported_type(:onreadtype, [:rclr, :rset, :ruser])
      end

      def test_assigning_onwritetype_value_to_unsupported_property_is_rejected
        run_property_assignment_test_with_unsupported_type(
          :onwritetype, [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser]
        )
      end

      def test_assigning_precedencetype_value_to_unsupported_property_is_rejected
        run_property_assignment_test_with_unsupported_type(:precedencetype, [:hw, :sw])
      end

      def def test_assigning_addressingtype_value_to_unsupported_property_is_rejected
        run_property_assignment_test_with_unsupported_type(:addressingtype, [:compact, :regalign, :fullalign])
      end

      def test_assigning_property_reference_value_to_not_supported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              external mem {
                reg {
                  field { sw = rw; hw = r; } b;
                } b;
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

        [:sw].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected accesstype"
          )
        end

        # Assigning property reference to mementries and memwidth does not occur
        # because dynamic assignment to these properties is not allowed.
      end

      def test_assigning_container_reference_value_to_not_supported_property_is_rejected
        template = proc do |layer, prop_name|
          case layer
          when :addrmap, :regfile
            <<~RDL
              addrmap my_map {
                #{layer} {
                  reg {
                    field { sw = rw; hw = r; } a;
                  } a;
                } a;
                external mem {
                  reg {
                    field { sw = rw; hw = r; } b;
                  } b;
                } b;
                b->#{prop_name} = a;
              };
            RDL
          when :mem
            <<~RDL
              addrmap my_map {
                external mem {
                  reg {
                    field { sw = rw; hw = r; } a;
                  } a;
                } a;
                external mem {
                  reg {
                    field { sw = rw; hw = r; } b;
                  } b;
                } b;
                b->#{prop_name} = a;
              };
            RDL
          when :reg
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
                external mem {
                  reg {
                    field { sw = rw; hw = r; } b;
                  } b;
                } b;
                b->#{prop_name} = a;
              };
            RDL
          when :field
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
                external mem {
                  reg {
                    field { sw = rw; hw = r; } b;
                  } b;
                } b;
                b->#{prop_name} = a.a;
              };
            RDL
          end
        end

        [:addrmap, :regfile, :mem, :reg, :field].each do |layer|
          [:name, :desc].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected string"
            )
          end

          [:sw].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected accesstype"
            )
          end

          # Assigning container reference to mementries and memwidth does not occur
          # because dynamic assignment to these properties is not allowed.
        end
      end

      def test_dynamic_assignment_to_supported_property_is_allowed
        { name: 'foo', desc: 'bar' }.each do |prop_name, prop_value|
          value =
            if prop_value.is_a?(::String)
              "\"#{prop_value}\""
            else
              prop_value
            end
          mem = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              external mem {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a;
              a->#{prop_name} = #{value};
            };
          RDL
          assert_property_value(mem, prop_name, prop_value)
        end
      end

      def test_dynamic_assignment_to_unsupported_property_is_rejected
        { mementries: 8, memwidth: 32 }.each do |prop_name, prop_value|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                external mem {
                  reg {
                    field { sw = rw; hw = r; } a;
                  } a;
                } a;
                a->#{prop_name} = #{prop_value};
              };
            RDL
            "dynamic assignment to #{prop_name} property not allowed"
          )
        end
      end

      def test_reference_to_unsupported_property_is_rejected
        [:name, :desc, :mementries, :memwidth, :sw].each do |prop_name|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                external mem {
                  reg {
                    field { sw = rw; hw = r; } a;
                  } a;
                } a;
                reg {
                  field { sw = rw; hw = r; } b;
                } b;
                b.b->swwe = a->#{prop_name};
              };
            RDL
            "reference to #{prop_name} property not allowed"
          )
        end
      end

      def test_element_assignment_to_allow_listed_property_is_allowed
        mems = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            external mem {
              reg { field { sw = rw; hw = r; } a; } a;
            } a[2];
            a[0]->name = "element name";
            a[0]->desc = "element desc";
          };
        RDL

        assert_property_value(mems[0], :name, 'element name')
        assert_property_value(mems[1], :name, 'a')
        assert_property_value(mems[0], :desc, 'element desc')
        assert_property_value(mems[1], :desc, '')
      end

      # No rejection test: name and desc are the only dynamically
      # assignable mem properties, and both are allow-listed.
    end
  end
end
