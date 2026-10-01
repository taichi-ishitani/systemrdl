# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestEnum < TestCase
      def test_defining_enum_with_automatic_value_assignment
        enum = evaluate(<<~'RDL').types[0]
          enum abc {
            A;
            B;
            C;
          };
        RDL

        assert_enum(
          enum, :abc,
          { name: :A, value: 0, width: 64 },
          { name: :B, value: 1, width: 64 },
          { name: :C, value: 2, width: 64 },
        )
      end

      def test_defining_enum_with_explicit_value_assignment
        enum = evaluate(<<~'RDL').types[0]
          enum abc {
            A = 1'd0;
            B = 2'd1;
            C = 3'd2;
          };
        RDL

        assert_enum(
          enum, :abc,
          { name: :A, value: 0, width: 3 },
          { name: :B, value: 1, width: 3 },
          { name: :C, value: 2, width: 3 },
        )

        enum = evaluate(<<~'RDL').types[0]
          enum myPartiallyAssignedEnum {
            a ;
            b ;
            c = 8'h6 ;
            d ;
            e = 8'h12 ;
            f ;
          } ;
        RDL

        assert_enum(
          enum, :myPartiallyAssignedEnum,
          { name: :a, value: 0x00, width: 8 },
          { name: :b, value: 0x01, width: 8 },
          { name: :c, value: 0x06, width: 8 },
          { name: :d, value: 0x07, width: 8 },
          { name: :e, value: 0x12, width: 8 },
          { name: :f, value: 0x13, width: 8 },
        )

        enum = evaluate(<<~RDL).types[0]
          enum MyBoolean {
            T = true;
            F = false;
          };
        RDL

        assert_enum(
          enum, :MyBoolean,
          { name: :T, value: 1, width: 1 },
          { name: :F, value: 0, width: 1 }
        )
      end

      def test_defining_enum_with_property_assignments
        enum = evaluate(<<~'RDL').types[0]
          enum myBitFieldEncoding {
            first_entry {};
            second_entry {
              name = "second entry";
            };
            third_entry = 8'hef {
              name = "third entry, just like others";
              desc = "this value has a special documentation";
            };
          };
        RDL

        assert_enum(
          enum, :myBitFieldEncoding,
          {
            name: :first_entry, value: 0x00, width: 8,
            properties: { name: 'first_entry', desc: '' }
          },
          {
            name: :second_entry, value: 0x01, width: 8,
            properties: { name: 'second entry', desc: '' }
          },
          {
            name: :third_entry, value: 0xef, width: 8,
            properties: { name: 'third entry, just like others', desc: 'this value has a special documentation' }
          }
        )
      end

      def test_non_integral_enum_member_value_is_rejected
        [
          [:string, '"foo"'], [:accesstype, 'rw'], [:onreadtype, 'rclr'],
          [:onwritetype, 'woset'], [:addressingtype, 'compact']
        ].each do |(type, value)|
          assert_raises_evaluation_error(
            <<~RDL,
              enum foo {
                A = #{value};
              };
            RDL
            "non integral enum member value: A (#{type})"
          )
        end
      end

      def assert_enum(enum, name, *members)
        assert_equal(name, enum.name)
        members.each_with_index do |values, i|
          enum_member = enum.members[i]
          assert_enum_member(enum_member, values[:name], values[:value], values[:width], values[:properties])
        end
      end

      def assert_enum_member(enum_member, name, value, width, properties)
        assert_equal(name, enum_member.name)
        assert_evaluated_value(enum_member.value, :bit, { value:, width: })
        properties&.each do |prop_name, prop_value|
          assert_property_value(enum_member, prop_name, prop_value)
        end
      end
    end
  end
end
