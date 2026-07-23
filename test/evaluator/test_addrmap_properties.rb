# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestAddrMapProperties < TestCase
      def test_property_initialization
        addrmap = evaluate(<<~'RDL').instances[0]
          addrmap some_reg {};
        RDL

        assert_property(addrmap, :name, [:string], value: 'some_reg')
        assert_property(addrmap, :desc, [:string], value: '')
        assert_property(addrmap, :alignment, [:longint])
        assert_property(addrmap, :sharedextbus, [:boolean], value: false)
        assert_property(addrmap, :errextbus, [:boolean], value: false)
        assert_property(addrmap, :bigendian, [:boolean], value: false)
        assert_property(addrmap, :littleendian, [:boolean], value: false)
        assert_property(addrmap, :addressing, [:addressingtype], value: :regalign)
        assert_property(addrmap, :rsvdset, [:boolean], value: false)
        assert_property(addrmap, :rsvdsetX, [:boolean], value: false)
        assert_property(addrmap, :msb0, [:boolean], value: false)
        assert_property(addrmap, :lsb0, [:boolean], value: false)
      end

      def test_assigning_integral_value_to_supported_property_is_allowed
        template = proc do |prop_name, include_zero|
          if include_zero
            <<~RDL
              addrmap a { #{prop_name} = 0    ; reg { field { sw = r; hw = r; } a; } a; };
              addrmap b { #{prop_name} = 1    ; reg { field { sw = r; hw = r; } a; } a; };
              addrmap c { #{prop_name} = 1'd0 ; reg { field { sw = r; hw = r; } a; } a; };
              addrmap d { #{prop_name} = 1'd1 ; reg { field { sw = r; hw = r; } a; } a; };
              addrmap e { #{prop_name} = false; reg { field { sw = r; hw = r; } a; } a; };
              addrmap f { #{prop_name} = true ; reg { field { sw = r; hw = r; } a; } a; };
            RDL
          else
            <<~RDL
              addrmap a { #{prop_name} = 1    ; reg { field { sw = r; hw = r; } a; } a; };
              addrmap b { #{prop_name} = 1'd1 ; reg { field { sw = r; hw = r; } a; } a; };
              addrmap c { #{prop_name} = true ; reg { field { sw = r; hw = r; } a; } a; };
            RDL
          end
        end

        [:alignment].each do |prop_name|
          addrmaps = evaluate(template[prop_name, false]).instances
          assert_property_value(addrmaps[0], prop_name, 1)
          assert_property_value(addrmaps[1], prop_name, 1)
          assert_property_value(addrmaps[2], prop_name, 1)
        end

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          addrmaps = evaluate(template[prop_name, true]).instances
          assert_property_value(addrmaps[0], prop_name, false)
          assert_property_value(addrmaps[1], prop_name, true)
          assert_property_value(addrmaps[2], prop_name, false)
          assert_property_value(addrmaps[3], prop_name, true)
          assert_property_value(addrmaps[4], prop_name, false)
          assert_property_value(addrmaps[5], prop_name, true)
        end
      end

      def test_assigning_integral_value_to_unsupported_property_is_rejected
        {
          name: 'string', desc: 'string', addressing: 'addressingtype'
        }.each do |prop_name, expected_type|
          {
            '0' => :bit, '1' => :bit, "16'd0" => :bit, "16'd1" => :bit,
            'true' => :boolean, 'false' => :boolean
          }.each do |value, value_type|
            assert_raises_evaluation_error(
              <<~RDL,
                addrmap my_map {
                  #{prop_name} = #{value};
                  reg {
                    field { sw = r; hw = r; } a;
                  } a;
                };
              RDL
              "#{value_type} type not supported by #{prop_name} property: expected #{expected_type}"
            )
          end
        end
      end

      def test_assigning_string_value_to_supported_property_is_allowed
        addrmap = evaluate(<<~RDL).instances[0]
          addrmap my_map {
            name = "foo";
            desc = "bar";
            reg {
              field { sw = r; hw = r; } a;
            } a;
          };
        RDL
        assert_property_value(addrmap, :name, 'foo')
        assert_property_value(addrmap, :desc, 'bar')
      end

      def test_assigning_string_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          <<~RDL
            addrmap my_map {
              #{prop_name} = "foo";
              reg {
                field { sw = r; hw = r; } a;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:addressing].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "string type not supported by #{prop_name} property: expected addressingtype"
          )
        end
      end

      def test_assigning_accesstype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rw, :wr, :r, :w, :rw1, :w1].sample
          <<~RDL
            addrmap my_map {
              #{prop_name} = #{value};
              reg {
                field { sw = r; hw = r; } a;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:addressing].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "accesstype type not supported by #{prop_name} property: expected addressingtype"
          )
        end
      end

      def test_assigning_onreadtype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:rclr, :rset, :ruser].sample
          <<~RDL
            addrmap my_map {
              #{prop_name} = #{value};
              reg {
                field { sw = r; hw = r; } a;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:addressing].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onreadtype type not supported by #{prop_name} property: expected addressingtype"
          )
        end
      end

      def test_assigning_onwritetype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:woset, :woclr, :wot, :wzs, :wzc, :wzt, :wclr, :wset, :wuser].sample
          <<~RDL
            addrmap my_map {
              #{prop_name} = #{value};
              reg {
                field { sw = w; hw = r; } a;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:addressing].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "onwritetype type not supported by #{prop_name} property: expected addressingtype"
          )
        end
      end

      def test_assigning_precedencetype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:hw, :sw].sample
          <<~RDL
            addrmap my_map {
              #{prop_name} = #{value};
              reg {
                field { sw = r; hw = r; } a;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:addressing].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "precedencetype type not supported by #{prop_name} property: expected addressingtype"
          )
        end
      end

      def test_assigning_addressingtype_value_to_supported_property_is_allowed
        [:compact, :regalign, :fullalign].each do |prop_value|
          addrmap = evaluate(<<~RDL).instances[0]
            addrmap my_map {
              addressing = #{prop_value};
              reg {
                field { sw = r; hw = r; } a;
              } a;
            };
          RDL
          assert_property_value(addrmap, :addressing, prop_value)
        end
      end

      def test_assigning_addressingtype_value_to_unsupported_property_is_rejected
        template = proc do |prop_name|
          value = [:compact, :regalign, :fullalign].sample
          <<~RDL
            addrmap my_map {
              #{prop_name} = #{value};
              reg {
                field { sw = r; hw = r; } a;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
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
              #{prop_name} = a.a->ored;
              reg {
                field { sw = r; hw = r; } b;
              } b;
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

        [
          :sharedextbus, :errextbus, :bigendian, :littleendian,
          :rsvdset, :rsvdsetX, :msb0, :lsb0
        ].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected boolean"
          )
        end

        [:addressing].each do |prop_name|
          assert_raises_evaluation_error(
            template[prop_name],
            "property_reference type not supported by #{prop_name} property: expected addressingtype"
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
                #{prop_name} = a;
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
                #{prop_name} = a;
              };
            RDL
          when :reg
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                } a;
                #{prop_name} = a;
              };
            RDL
          when :field
            <<~RDL
              addrmap my_map {
                reg {
                  field { sw = r; hw = r; } a;
                } a;
                #{prop_name} = a.a;
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

          [
            :sharedextbus, :errextbus, :bigendian, :littleendian,
            :rsvdset, :rsvdsetX, :msb0, :lsb0
          ].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected boolean"
            )
          end

          [:addressing].each do |prop_name|
            assert_raises_evaluation_error(
              template[layer, prop_name],
              "#{layer}_reference type not supported by #{prop_name} property: expected addressingtype"
            )
          end
        end
      end

      def test_dynamic_assignment_to_supported_property_is_allowed
        {
          name: 'foo', desc: 'bar', bigendian: true, littleendian: true
        }.each do |prop_name, prop_value|
          value =
            if prop_value.is_a?(::String)
              "\"#{prop_value}\""
            else
              prop_value
            end
          addrmap = evaluate(<<~RDL).instances[0].instances[0]
            addrmap my_map {
              addrmap {
                reg {
                  field { sw = rw; hw = r; } a;
                } a;
              } a;
              a->#{prop_name} = #{value};
            };
          RDL

          assert_property_value(addrmap, prop_name, prop_value)
        end
      end

      def test_dynamic_assignment_to_unsupported_property_is_rejected
        {
          alignment: 4, sharedextbus: true, errextbus: true, addressing: :compact,
          rsvdset: true, rsvdsetX: true, msb0: true, lsb0: true
        }.each do |prop_name, prop_value|
          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                addrmap {
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
    end
  end
end
