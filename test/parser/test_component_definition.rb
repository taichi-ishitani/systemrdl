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
            prop_assignment(:sw, access_type(:rw)),
            prop_assignment(:hw, access_type(:rw))
          ),
          code
        )

        code = "field { reset = 1'b1; } a;"
        assert_parses(
          field_anonymous_definition(
            prop_assignment(:reset, verilog_number("1'b1")),
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
            prop_assignment(:anded),
            component_insts(component_inst(:a, array(4), reset_value(number(0))))
          ),
          code
        )
      end

      def test_register_component
        code = 'reg myReg { field {} data[31:0]; };'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            field_anonymous_definition(
              component_insts(component_inst(:data, range(31, 0)))
            )
          ),
          code
        )

        code = 'reg myReg {} reg_a[2], reg_b[2][4];'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(:reg_a, array(2)),
              component_inst(:reg_b, array(2), array(4))
            )
          ),
          code
        )

        code = 'reg myReg {} reg_a @ 0x10;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(:reg_a, address_assignment(number('0x10')))
            )
          ),
          code
        )

        code = 'reg myReg {} reg_b[10] @0x100 += 0x10;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(
                :reg_b,
                array(10),
                address_assignment(number('0x100')),
                address_stride(number('0x10')),
              )
            )
          ),
          code
        )

        code = 'reg myReg {} reg_a %= 0x10;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            component_insts(
              component_inst(:reg_a, address_alignment(number('0x10')))
            )
          ),
          code
        )

        code = 'reg {} external reg_a , reg_b;'
        assert_parses(
          reg_anonymous_definition(
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = 'reg myReg {} external reg_a , reg_b;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = 'external reg {} reg_a , reg_b;'
        assert_parses(
          reg_anonymous_definition(
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = 'external reg myReg {} reg_a , reg_b;'
        assert_parses(
          reg_named_definition(
            id(:myReg),
            external_component_insts(
              component_inst(:reg_a), component_inst(:reg_b)
            )
          ),
          code
        )

        code = <<~'R'
          reg {
            field f_type {};
            f_type some_field;
          } some_reg;
        R
        assert_parses(
          reg_anonymous_definition(
            field_named_definition(id(:f_type)),
            explicit_component_inst(
              :f_type,
              component_insts(component_inst(:some_field))
            ),
            component_insts(component_inst(:some_reg))
          ),
          code
        )

        code = <<~'R'
          reg {
            field {} f1;
            f1->name = "New name for Field 1";
          } some_reg;
        R
        assert_parses(
          reg_anonymous_definition(
            field_anonymous_definition(
              component_insts(component_inst(:f1))
            ),
            post_prop_assignment(
              :f1, :name, string('"New name for Field 1"')
            ),
            component_insts(
              component_inst(:some_reg)
            )
          ),
          code
        )

        code = <<~'R'
          reg my32bitReg {
            regwidth = 32;
            accesswidth = 16;
            field {} a[16]=0;
            field {} b[32]=1;
          };
        R
        assert_parses(
          reg_named_definition(
            id(:my32bitReg),
            prop_assignment(:regwidth, number(32)),
            prop_assignment(:accesswidth, number(16)),
            field_anonymous_definition(
              component_insts(
                component_inst(:a, array(16), reset_value(number(0)))
              )
            ),
            field_anonymous_definition(
              component_insts(
                component_inst(:b, array(32), reset_value(number(1)))
              )
            )
          ),
          code
        )
      end

      def reg_anonymous_definition(*children)
        s(:component_anon_def, 'reg', *children)
      end

      def reg_named_definition(*children)
        s(:component_named_def, 'reg', *children)
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

      def external_component_insts(*children)
        s(:external_component_insts, *children)
      end

      def explicit_component_inst(component_name, insts)
        s(:explicit_component_inst, id(component_name), insts)
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

      def address_assignment(expression)
        s(:address_assignment, expression)
      end

      def address_stride(expression)
        s(:address_stride, expression)
      end

      def address_alignment(expression)
        s(:address_alignment, expression)
      end

      def number(n)
        s(:number, n.to_s)
      end

      def verilog_number(n)
        s(:verilog_number, n)
      end

      def string(s)
        s(:string, s)
      end

      def access_type(type)
        s(:access_type, type.to_s)
      end

      def prop_assignment(prop_name, value = nil)
        s(:prop_assignment, *[id(prop_name), value].compact)
      end

      def post_prop_assignment(inst_name, prop_name, value)
        prop_ref = s(
          :prop_ref,
          s(:instance_ref, s(:instance_ref_element, id(inst_name))),
          id(prop_name)
        )
        s(:post_prop_assignment, prop_ref, value)
      end
    end
  end
end
