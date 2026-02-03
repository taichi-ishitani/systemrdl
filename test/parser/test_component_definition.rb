# frozen_string_literal: true

require_relative 'test_helper'

module SystemRDL
  module Parser
    class TestComponentDefinition < TestCase
      def test_field_component
        code = 'field {} singlebitfield;'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:singlebitfield))
          ),
          code
        )

        code = 'field {} somefield[4];'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:somefield, array(4)))
          ),
          code
        )

        code = 'field {} somefield[3:0];'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:somefield, range(3, 0)))
          ),
          code
        )

        code = 'field {} somefield[0:31];'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:somefield, range(0, 31)))
          ),
          code
        )

        code = 'field f { sw = rw; hw = rw; };'
        assert_parses(
          field_named_definition(
            id(:f),
            prop_assignment(id(:sw), access_type(:rw)),
            prop_assignment(id(:hw), access_type(:rw))
          ),
          code
        )

        code = "field { reset = 1'b1; } a;"
        assert_parses(
          field_anonymous_definition(
            prop_assignment(id(:reset), verilog_number("1'b1")),
            component_insts(component_inst(:a))
          ),
          code
        )

        code = 'field {} b=0;'
        assert_parses(
          field_anonymous_definition(
            component_insts(component_inst(:b, reset_value(number(0))))
          ),
          code
        )

        code = 'field { anded;} a[4]=0;'
        assert_parses(
          field_anonymous_definition(
            prop_assignment(id(:anded)),
            component_insts(component_inst(:a, array(4), reset_value(number(0))))
          ),
          code
        )
      end

      def field_anonymous_definition(*children)
        s(:component_anon_def, 'field', *children)
      end

      def field_named_definition(*children)
        s(:component_named_def, 'field', *children)
      end

      def component_insts(*children)
        s(:component_insts, *children)
      end

      def component_inst(id, *children)
        s(:component_inst, id(id), *children)
      end

      def id(name)
        s(:id, name.to_s)
      end

      def array(size)
        s(:array, number(size))
      end

      def range(head, tail)
        s(:range, number(head), number(tail))
      end

      def reset_value(value)
        s(:reset_value, value)
      end

      def number(n)
        s(:number, n.to_s)
      end

      def verilog_number(n)
        s(:verilog_number, n)
      end

      def access_type(type)
        s(:access_type, type.to_s)
      end

      def prop_assignment(id, value = nil)
        s(:prop_assignment, *[id, value].compact)
      end
    end
  end
end
