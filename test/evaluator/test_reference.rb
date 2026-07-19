# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Evaluator
    class TestReference < TestCase
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
    end
  end
end
