# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:component_definition) do
        (
          (component_def >> component_inst_type >> component_insts) |
          (component_def >> component_insts) |
          (component_inst_type >> component_def >> component_insts) |
          (component_named_def)
        ) >> spaces? >> spaced(';')
      end

      rule(:component_def) do
        component_named_def | component_anon_def
      end

      rule(:component_named_def) do
        (
          component_type >> spaces >> id.as(:component_id) >> spaces? >> component_body
        ).as(:component_def)
      end

      rule(:component_anon_def) do
        (
          component_type >> spaces? >> component_body
        ).as(:component_def)
      end

      rule(:component_body) do
        element =
          (
            component_definition | property_assignment
          ) >> spaces?
        bracketed(element.repeat(1), '{', '}').as(:component_body) |
          bracketed(spaces?, '{', '}')
      end

      rule(:component_insts) do
        (
          (component_inst >> spaced(',')).repeat >> component_inst
        ).as(:component_insts)
      end

      rule(:component_inst) do
        inst_id = (
          id.as(:id) >> spaces? >> array.as(:array) |
          id.as(:id) >> spaces? >> range.as(:range) |
          id.as(:id) >> spaces?
        ).as(:component_inst_id)
        assignments = (
          inst_operation('=') >> inst_operation('@') >>
          inst_operation('+=') >> inst_operation('%=')
        ).as(:component_inst_assignments)

        inst_id >> assignments >> spaces?
      end

      private

      def component_type
        [kw_addrmap, kw_regfile, kw_reg, kw_field, kw_mem]
          .inject(:|).as(:component_type)
      end

      def component_inst_type
        (
          kw_external | kw_internal
        ).as(:component_inst_type) >> spaces
      end

      def inst_operation(operator)
        (
          spaced(operator).as(:operator) >>
          constant_expression.as(:operand)
        ).as(:inst_operation).maybe
      end
    end

    define_transformer do
      # rule(
      #   component_def: subtree(:component_def),
      #   component_inst_type: simple(:inst_type),
      #   component_insts: subtree(:component_insts)
      # ) do
      # end

      rule(
        component_def: subtree(:component_def),
        component_insts: subtree(:component_insts)
      ) do
        type, id, body =
          fetch_values(component_def, :component_type, :component_id, :component_body)
        insts = untyped_component_insts(component_insts, nil)

        component_definition(type).new(type.position, id, to_array(body), insts)
      end

      # rule(
      #   component_inst_type: simple(:inst_type),
      #   component_def: subtree(:component_def),
      #   component_insts: subtree(:component_insts)
      # ) do
      # end

      rule(
        component_def: subtree(:component_def)
      ) do
        type, id, body =
          fetch_values(component_def, :component_type, :component_id, :component_body)
        component_definition(type).new(type.position, id, body, nil)
      end

      rule(
        component_inst_id: subtree(:id),
        component_inst_assignments: subtree(:assignments)
      ) do
        inst_id, array, range = fetch_values(id, :id, :array, :range)
        assignment_list = to_array(assignments)
        AST::ComponentInstance
          .new(inst_id.position, inst_id, array, range, assignment_list)
      end

      rule(inst_operation: { operator: simple(:oprator), operand: simple(:operand) }) do
        AST::InstanceAssignment
          .new(oprator.position, oprator.str.to_sym, operand)
      end

      private

      def component_definition(component_type)
        {
          'field' => AST::FieldDefinition
        }[component_type.str]
      end

      def untyped_component_insts(insts, inst_type)
        inst_list = to_array(insts)
        position = inst_list.first.position
        AST::ComponentInstances.new(position, nil, inst_type, nil, inst_list)
      end
    end
  end
end
