# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestIdentifier < TestCase
      def test_unresolvable_instance_error_on_rhs
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { hwclr = foo; } a;
              } a;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                a->hwclr = foo;
              } a;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                a->hwclr = foo->ored;
              } a;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a.a->hwclr = foo.b;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a.a->hwclr = foo.b->ored;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a.a->hwclr = b.foo;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a.a->hwclr = b.foo->ored;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b[2];
              a.a->hwclr = b[2].b;
            };
          RDL
          'unresolvable instance: b[2]'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b[2];
              a.a->hwclr = b[2].b->ored;
            };
          RDL
          'unresolvable instance: b[2]'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a.a->hwclr = b[0].b->ored;
            };
          RDL
          'unresolvable instance: b[0]'
        )
      end

      def test_unresolvable_instance_error_on_lhs
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                foo->hwclr = a;
              } a;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              foo.a->hwclr = b.b;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a.foo->hwclr = b.b;
            };
          RDL
          'unresolvable instance: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a[2];
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a[2].a->hwclr = b.b;
            };
          RDL
          'unresolvable instance: a[2]'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
              } a;
              reg {
                field { sw = rw; hw = r; } b;
              } b;
              a[0].a->hwclr = b.b;
            };
          RDL
          'unresolvable instance: a[0]'
        )
      end

      def test_undefined_property_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { foo; } a;
              } a;
            };
          RDL
          'undefined property: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                a->foo;
              } a;
            };
          RDL
          'undefined property: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field { sw = rw; hw = r; } a;
                field { sw = rw; hw = r; } b;
                a->hwclr = b->foo;
              } a;
            };
          RDL
          'undefined property: foo'
        )
      end

      def test_undefined_component_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              foo a;
            };
          RDL
          'undefined component: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              regfile {
                foo a;
              } a;
            };
          RDL
          'undefined component: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                foo a;
              } a;
            };
          RDL
          'undefined component: foo'
        )
      end

      def test_duplicated_instance_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field my_field { sw = rw; hw = r; };
                my_field a;
                my_field a;
              } a;
            };
          RDL
          'duplicated instance: a'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg my_reg { field { sw = rw; hw = r; } a; };
              my_reg a;
              my_reg a;
            };
          RDL
          'duplicated instance: a'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg my_reg { field { sw = rw; hw = r; } a; };
              my_reg a[2];
              my_reg a;
            };
          RDL
          'duplicated instance: a'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg my_reg { field { sw = rw; hw = r; } a; };
              my_reg a;
              my_reg a[2];
            };
          RDL
          'duplicated instance: a'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg my_reg { field { sw = rw; hw = r; } a; };
              my_reg a[2];
              my_reg a[2];
            };
          RDL
          'duplicated instance: a'
        )
      end

      def test_duplicated_component_error
        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg {
                field foo { sw = rw; hw = r; };
                field foo { sw = rw; hw = r; };
                foo a;
              } a;
            };
          RDL
          'duplicated component: foo'
        )

        assert_raises_evaluation_error(
          <<~'RDL',
            addrmap my_map {
              reg foo {
                field { sw = rw; hw = r; } a;
              };
              reg foo {
                field { sw = rw; hw = r; } a;
              };
              foo a;
            };
          RDL
          'duplicated component: foo'
        )
      end

      def test_identifier_namespace_independence
        reg = evaluate(<<~'RDL').instances[0].instances[0]
          addrmap my_map {
            reg {
              field accesswidth { sw = rw; hw = r; };
              accesswidth accesswidth;
              accesswidth = 32;
            } a;
          };
        RDL

        assert_property_value(reg, :accesswidth, 32)
        assert_property_value(reg.instances[0], :name, 'accesswidth')
      end

      def test_identifier_independence_across_instances
        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            reg { field { sw = rw; hw = r; } f; } r0;
            reg { field { sw = rw; hw = r; } f; } r1;
          };
        RDL

        assert_property_value(regs[0].instances[0], :name, 'f')
        assert_property_value(regs[1].instances[0], :name, 'f')

        regs = evaluate(<<~'RDL').instances[0].instances
          addrmap my_map {
            reg {
              field foo { sw = rw; hw = r; };
              foo f0;
            } r0;
            reg {
              field foo { sw = rw; hw = r; };
              foo f1;
            } r1;
          };
        RDL

        assert_property_value(regs[0].instances[0], :name, 'f0')
        assert_property_value(regs[1].instances[0], :name, 'f1')
      end
    end
  end
end
