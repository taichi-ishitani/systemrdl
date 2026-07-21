# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestProperty < TestCase
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
    end
  end
end
