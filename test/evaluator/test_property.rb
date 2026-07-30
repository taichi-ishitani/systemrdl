# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestProperty < TestCase
      def test_duplicated_property_assignment_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field {
                  sw = r;
                  sw = rw;
                  hw = r;
                } a;
              } a;
            };
          RDL
          'sw already assigned in this scope'
        )
      end

      def test_default_property_applied
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            default regwidth = 64;
            default shared = true;
            default hw = r;
            reg {
              default sw = rw;
              default reset = 1;
              default rclr;
              field {} a;
              field {} b;
            } a[2];
          };
        RDL

        regs.each do |reg|
          assert_property_value(reg, :accesswidth, 64)
          assert_property_value(reg, :shared, true)
        end

        fields = regs.flat_map(&:instances)
        fields.each do |field|
          assert_property_value(field, :sw, :rw)
          assert_property_value(field, :hw, :r)
          assert_property_value(field, :reset, 1)
          assert_property_value(field, :rclr, true)
        end

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            reg my_reg {
              default sw = rw;
              default hw = r;
              field {} a;
              field {} b;
            };
            my_reg a;
            my_reg b;
          };
        RDL

        fields = regs.flat_map(&:instances)
        fields.each do |field|
          assert_property_value(field, :sw, :rw)
          assert_property_value(field, :hw, :r)
        end
      end

      def test_default_property_priority_between_scopes
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            default sw = r;
            default hw = w;
            reg {
              default sw = rw;
              default hw = r;
              field {} a;
            } a;
          };
        RDL

        assert_property_value(fields[0], :sw, :rw)
        assert_property_value(fields[0], :hw, :r)
      end

      def test_explicit_assignment_overrides_default
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              default sw = r;
              default hw = r;
              field {} a;
              field { sw = rw; } b;
            } a;
          };
        RDL

        assert_property_value(fields[0], :sw, :r)
        assert_property_value(fields[1], :sw, :rw)
      end

      def test_default_not_applied_to_self
        reg = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap my_map {
            reg {
              default regwidth = 64;
              field { sw = rw; hw = r; } a;
            } a;
          };
        RDL

        assert_property_value(reg, :regwidth, 32)
      end

      def test_default_applies_only_after_declaration
        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            reg {
              field { hw = r; } a;
              default sw = r;
              field { hw = r; } b;
            } a;
          };
        RDL

        assert_property_value(fields[0], :sw, :rw)
        assert_property_value(fields[1], :sw, :r)

        fields = evaluate(<<~'RDL').instances[0].instances[0].instances
          addrmap my_map {
            field my_field { sw = rw; hw = r; };
            reg {
              default name = "default name";
              field { sw = rw; hw = r; } a;
              field { sw = rw; hw = r; name = "new name"; } b;
              my_field c;
            } a;
          };
        RDL

        assert_property_value(fields[0], :name, 'default name')
        assert_property_value(fields[1], :name, 'new name')
        assert_property_value(fields[2], :name, 'c')
      end

      def test_default_property_type_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                default sw = 1;
                field {} a;
              } a;
            };
          RDL
          'bit type not supported by sw property: expected accesstype'
        )
      end

      def test_undefined_default_property_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                default foo = 1;
                field {} a;
              } a;
            };
          RDL
          'undefined property: foo'
        )
      end

      def test_default_duplicated_assignment_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                default sw = r;
                default sw = rw;
                field {} a;
              } a;
            };
          RDL
          'sw already assigned in this scope'
        )
      end

      def test_dynamic_assignment_override_in_same_scope
        field = evaluate(<<~'RDL').instances[0].instances[0].instances[0]
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a;
              a->name = "first";
              a->name = "second";
            } a;
          };
        RDL

        assert_property_value(field, :name, 'second')
      end

      def test_dynamic_assignment_override_between_scopes
        field = evaluate(<<~'RDL').instances[0].instances[0].instances[0]
          addrmap my_map {
            reg {
              field { sw = rw; hw = r; } a;
              a->name = "inner";
            } a;
            a.a->name = "outer";
          };
        RDL

        assert_property_value(field, :name, 'outer')
      end

      def test_whole_array_assignment_is_allowed
        regs = evaluate(<<~'RDL').instances[0].instances[0..1]
          addrmap my_map {
            reg { field { sw = rw; hw = r; } a; } a[2];
            reg { field { sw = rw; hw = r; } a; } b;
            reg { field { sw = rw; hw = r; } a; } c[2];
            a->name = "whole array";
            a.a->hwenable = b.a;
            a.a->swwe = b.a->anded;
            a.a->hwclr = c[0].a;
            a.a->hwset = c[0].a->ored;
          };
        RDL

        regs.each do |reg|
          assert_property_value(reg, :name, 'whole array')
        end

        fields = regs.flat_map(&:instances)
        fields.each do |field|
          assert_property_reference_value(field, :hwenable, 'my_map.b.a')
          assert_property_reference_value(field, :swwe, 'my_map.b.a.anded')
          assert_property_reference_value(field, :hwclr, 'my_map.c[0].a')
          assert_property_reference_value(field, :hwset, 'my_map.c[0].a.ored')
        end
      end

      def test_whole_array_reference_value_is_rejected
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg { field { sw = rw; hw = r; } a; } a[2];
              reg { field { sw = rw; hw = r; } a; } b[2];
              a.a->hwenable = b.a;
            };
          RDL
          'reference to array instance not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg { field { sw = rw; hw = r; } a; } a[2];
              reg { field { sw = rw; hw = r; } a; } b[2];
              a.a->swwe = b.a->anded;
            };
          RDL
          'reference to array instance not allowed'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg { field { sw = rw; hw = r; } a; } a;
              reg { field { sw = rw; hw = r; } a; } b[2];
              a.a->hwenable = b.a;
            };
          RDL
          'reference to array instance not allowed'
        )
      end
    end
  end
end
