# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestParameterizedComponent < TestCase
      def test_instantiating_parameterized_component
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            field my_field #(
              onwritetype       ONWRITE     = woset,
              longint unsigned  FIELDWIDTH  = 1
            ) {
              sw = rw;
              hw = r;
              onwrite = ONWRITE;
              fieldwidth = FIELDWIDTH;
            };
            reg {
              my_field a;
              my_field #(.ONWRITE(woclr)) b;
              my_field #(.FIELDWIDTH(2)) c;
              my_field #(.ONWRITE(wot), .FIELDWIDTH(3)) d;
            } a;
          };
        RDL

        assert_property_value(fields[0], :onwrite, :woset)
        assert_property_value(fields[0], :fieldwidth, 1)

        assert_property_value(fields[1], :onwrite, :woclr)
        assert_property_value(fields[1], :fieldwidth, 1)

        assert_property_value(fields[2], :onwrite, :woset)
        assert_property_value(fields[2], :fieldwidth, 2)

        assert_property_value(fields[3], :onwrite, :wot)
        assert_property_value(fields[3], :fieldwidth, 3)
      end

      def test_parameter_dependency
        mems = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            mem fixed_mem #(
              longint unsigned word_size   = 32,
              longint unsigned memory_size = word_size * 4096
            ) {
              mementries = memory_size / word_size;
              memwidth   = word_size;
            };
            external fixed_mem a;
            external fixed_mem #(.word_size(64)) b;
            external fixed_mem #(.memory_size(1024)) c;
          };
        RDL

        assert_property_value(mems[0], :mementries, 4096)
        assert_property_value(mems[0], :memwidth, 32)

        assert_property_value(mems[1], :mementries, 4096)
        assert_property_value(mems[1], :memwidth, 64)

        assert_property_value(mems[2], :mementries, 32)
        assert_property_value(mems[2], :memwidth, 32)
      end

      def test_missing_mandatory_parameter
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              field my_field #(longint unsigned WIDTH) {
                sw = rw;
                hw = rw;
                fieldwidth = WIDTH;
              };
              reg {
                my_field a;
              } a;
            };
          RDL
          'missing mandatory parameter: WIDTH'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map #(longint unsigned ALIGNMENT) {
              alignment = ALIGNMENT;
              reg {
                field { sw = rw; hw = r; } a;
              } a;
            };
          RDL
          'missing mandatory parameter: ALIGNMENT'
        )
      end

      def test_overriding_unknown_parameter
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              field my_field #(longint unsigned WIDTH = 8) {
                sw = rw;
                hw = r;
                fieldwidth = WIDTH;
              };
              reg {
                my_field #(.undefined(16)) a;
              } a;
            };
          RDL
          'unknown parameter: undefined'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              field my_field {
                sw = rw;
                hw = r;
                fieldwidth = 8;
              };
              reg {
                my_field #(.undefined(16)) a;
              } a;
            };
          RDL
          'unknown parameter: undefined'
        )
      end

      def test_duplicated_parameter_definition
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              field my_field #(
                longint unsigned WIDTH = 8,
                longint unsigned WIDTH = 4
              ) {
                sw = rw;
                hw = r;
                fieldwidth = WIDTH;
              };
              reg {
                my_field a;
              } a;
            };
          RDL
          'duplicated parameter: WIDTH'
        )
      end

      def test_duplicated_parameter_override
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              field my_field #(longint unsigned WIDTH = 8) {
                sw = rw;
                hw = r;
                fieldwidth = WIDTH;
              };
              reg {
                my_field #(.WIDTH(4), .WIDTH(2)) a;
              } a;
            };
          RDL
          'duplicated parameter override: WIDTH'
        )
      end

      def test_instance_name_conflicting_with_parameter_name
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg my_reg #(longint unsigned a = 8) {
                field { sw = rw; hw = r; } a;
              };
              my_reg a;
            };
          RDL
          'duplicated instance: a'
        )
      end

      def test_type_mismatch
        types = [
          :longint, :bit, :string, :boolean, :accesstype, :addressingtype,
          :onreadtype, :onwritetype
        ]
        values = [
          ['1', :longint], ["1'b1", :bit], ['"FOO"', :string], ['true', :boolean],
          ['rw', :accesstype], ['compact', :addressingtype], ['rclr', :onreadtype], ['woclr', :onwritetype]
        ]

        types.product(values) do |param_type, (value, value_type)|
          next if param_type == value_type
          next if (param_type in :longint | :bit | :boolean) && (value_type in :longint | :bit | :boolean)

          expected_type = param_type == :longint ? :bit : param_type
          actual_type = value_type == :longint ? :bit : value_type

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg my_reg #(#{param_type} A) {
                  field { sw = rw; hw = r; } a;
                };
                my_reg #(.A(#{value})) a;
              };
            RDL
            "type mismatch for A parameter: expected #{expected_type} actual #{actual_type}"
          )

          assert_raises_evaluation_error(
            <<~RDL,
              addrmap my_map {
                reg my_reg #(#{param_type} A = #{value}) {
                  field { sw = rw; hw = r; } a;
                };
                my_reg a;
              };
            RDL
            "type mismatch for A parameter: expected #{expected_type} actual #{actual_type}"
          )
        end
      end
    end
  end
end
