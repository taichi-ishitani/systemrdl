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
          enum, :abc, 64,
          { name: :A, value: 0 },
          { name: :B, value: 1 },
          { name: :C, value: 2 },
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
          enum, :abc, 3,
          { name: :A, value: 0 },
          { name: :B, value: 1 },
          { name: :C, value: 2 },
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
          enum, :myPartiallyAssignedEnum, 8,
          { name: :a, value: 0x00 },
          { name: :b, value: 0x01 },
          { name: :c, value: 0x06 },
          { name: :d, value: 0x07 },
          { name: :e, value: 0x12 },
          { name: :f, value: 0x13 },
        )

        enum = evaluate(<<~'RDL').types[0]
          enum myPartiallyAssignedEnum {
            a = 8'hFF;
            b ;
            c = 9'h101;
          } ;
        RDL

        assert_enum(
          enum, :myPartiallyAssignedEnum, 9,
          { name: :a, value: 0x0FF },
          { name: :b, value: 0x100 },
          { name: :c, value: 0x101 },
        )

        enum = evaluate(<<~RDL).types[0]
          enum MyBoolean {
            T = true;
            F = false;
          };
        RDL

        assert_enum(
          enum, :MyBoolean, 1,
          { name: :T, value: 1 },
          { name: :F, value: 0 }
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
          enum, :myBitFieldEncoding, 8,
          {
            name: :first_entry, value: 0x00,
            properties: { name: 'first_entry', desc: '' }
          },
          {
            name: :second_entry, value: 0x01,
            properties: { name: 'second entry', desc: '' }
          },
          {
            name: :third_entry, value: 0xef,
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

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              enum foo {
                A = a;
              };
            };
          RDL
          'non integral enum member value: A (reg_ref)'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              enum foo {
                A = a.a;
              };
            };
          RDL
          'non integral enum member value: A (field_ref)'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              enum foo {
                A = a->regwidth;
              };
            };
          RDL
          'non integral enum member value: A (prop_ref)'
        )
      end

      def test_duplicated_enum_member_value_is_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            enum foo {
              A = 0;
              B = 0;
            };
          RDL
          'duplicated enum member value: B (0)'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            enum foo {
              A = 1'd0;
              B = 0;
            };
          RDL
          'duplicated enum member value: B (0)'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            enum foo {
              A;
              B = 0;
            };
          RDL
          'duplicated enum member value: B (0)'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            enum foo {
              A = 1;
              B = 0;
              C;
            };
          RDL
          'duplicated enum member value: C (1)'
        )
      end

      def test_enum_member_value_exceeding_bit_width_is_rejected
        assert_raises_evaluation_error(
          <<~RDL,
            enum foo {
              A = 8'hFF;
              B ;
            };
          RDL
          'enum member value out of range: B (value 256 width 8)'
        )

        assert_raises_evaluation_error(
          <<~RDL,
            enum foo {
              A = true;
              B ;
            };
          RDL
          'enum member value out of range: B (value 2 width 1)'
        )
      end

      def test_enum_literal
        assert_evaluates_enum_literal(
          { kind: :enum, name: :ab, width: 64 }, { name: :A, value: 0 }, 'ab::A'
        )
        assert_evaluates_enum_literal(
          { kind: :enum, name: :ab, width: 64 }, { name: :B, value: 1 }, 'ab::B'
        )

        assert_evaluates_enum_literal(
          { kind: :enum, name: :cd, width: 8 }, { name: :C, value: 0x10 }, 'cd::C'
        )
        assert_evaluates_enum_literal(
          { kind: :enum, name: :cd, width: 8 }, { name: :D, value: 0xFF }, 'cd::D'
        )

        assert_evaluates_enum_literal(
          { kind: :enum, name: :ef, width: 128 }, { name: :E, value: 0 }, 'ef::E'
        )
        assert_evaluates_enum_literal(
          { kind: :enum, name: :ef, width: 128 }, { name: :F, value: 1 }, 'ef::F'
        )
      end

      def test_unary_operation
        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0x10, '+cd::C')
        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0xF0, '-cd::C')
        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0xEF, '~cd::C')


        assert_evaluates_enum_expression({ kind: :bit, width: 64 }, 0, '+ab::A')
        assert_evaluates_enum_expression({ kind: :bit, width: 64 }, 0, '-ab::A')
        assert_evaluates_enum_expression({ kind: :bit, width: 64 }, 0xFFFF_FFFF_FFFF_FFFF, '~ab::A')

        assert_evaluates_enum_expression({ kind: :bit, width: 1 }, 1, '&cd::D')
        assert_evaluates_enum_expression({ kind: :bit, width: 1 }, 0, '&cd::C')

        assert_evaluates_enum_expression({ kind: :boolean}, true , '!ab::A')
        assert_evaluates_enum_expression({ kind: :boolean}, false, '!ab::B')
      end

      def test_binary_operation_between_enum_literals
        assert_evaluates_enum_expression({ kind: :bit, width: 64 }, 1   , 'ab::A + ab::B')
        assert_evaluates_enum_expression({ kind: :bit, width: 8  }, 0x0F, 'cd::C + cd::D')
        assert_evaluates_enum_expression({ kind: :bit, width: 8  }, 0xEF, 'cd::D - cd::C')

        assert_evaluates_enum_expression({ kind: :bit, width: 64  }, 1    , 'ab::A + ab::B')
        assert_evaluates_enum_expression({ kind: :bit, width: 128 }, 0x100, 'cd::D + ef::F')
        assert_evaluates_enum_expression({ kind: :bit, width: 128 }, 0x10 , 'cd::C + ef::E')

        assert_evaluates_enum_expression({ kind: :boolean }, true , 'ab::A == ef::E')
        assert_evaluates_enum_expression({ kind: :boolean }, false, 'ab::A != ef::E')
        assert_evaluates_enum_expression({ kind: :boolean }, true , 'ab::B == ef::F')
        assert_evaluates_enum_expression({ kind: :boolean }, true , 'ab::A < cd::C')
        assert_evaluates_enum_expression({ kind: :boolean }, false, 'cd::D <= ab::B')
      end

      def test_binary_operation_between_enum_literal_and_literal
        assert_evaluates_enum_expression({ kind: :bit, width: 64 }, 1    , 'ab::A + 1')
        assert_evaluates_enum_expression({ kind: :bit, width: 64 }, 0x100, 'cd::D + 1')

        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0x00, "cd::D + 8'd1")
        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0xFE, "cd::D - 8'd1")

        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0x10, "cd::C | 8'h00")
        assert_evaluates_enum_expression({ kind: :bit, width: 8 }, 0x00, "cd::C & 8'h00")

        assert_evaluates_enum_expression({ kind: :boolean }, true , 'cd::C == 0x10')
        assert_evaluates_enum_expression({ kind: :boolean }, true , 'ab::A == 0')
        assert_evaluates_enum_expression({ kind: :boolean }, false, 'ab::A == 1')
      end

      def assert_enum(enum, name, width, *members)
        assert_equal(name, enum.name)
        assert_equal(width, enum.width)
        members.each_with_index do |values, i|
          enum_member = enum.members[i]
          assert_enum_member(enum_member, values[:name], values[:value], values[:properties])
        end
      end

      def assert_enum_member(enum_member, name, value, properties)
        assert_equal(name, enum_member.name)
        assert_evaluated_value({ kind: :bit }, value, enum_member.value)
        properties&.each do |prop_name, prop_value|
          assert_property_value(enum_member, prop_name, prop_value)
        end
      end

      def assert_evaluates_enum_literal(expected_enum, expected_member, literal)
        value = evaluate_value("#{enum_defs}\n#{literal}", test: :constant_expression)
        assert_type(expected_enum, value.type)
        assert_equal(expected_member[:name], value.value.name)
        assert_value(expected_member[:value], value.value.value)
      end

      def assert_evaluates_enum_expression(expected_type, expected_value, expression)
        assert_evaluates_value(
          expected_type, expected_value, "#{enum_defs}\n#{expression}", test: :constant_expression
        )
      end

      def enum_defs
        <<~RDL
          enum ab {
            A;
            B;
          };
          enum cd {
            C = 8'h10;
            D = 8'hFF;
          };
          enum ef {
            E = 0;
            F = 128'd1;
          };
        RDL
      end
    end
  end
end
