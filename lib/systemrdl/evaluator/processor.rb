# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Processor < AST::Processor
      def on_id(node)
        id = node.children[0].to_sym
        Value.new(id, nil, nil, node.token_range)
      end

      def on_boolean(node)
        Boolean.new(node)
      end

      def on_number(node)
        Number.new(node)
      end

      def on_verilog_number(node)
        VerilogNumber.new(node)
      end

      def on_string(node)
        String.new(node)
      end

      def on_accesstype(node)
        AccessType.new(node)
      end

      def on_onreadtype(node)
        OnReadType.new(node)
      end

      def on_onwritetype(node)
        OnWriteType.new(node)
      end

      def on_addressingtype(node)
        AddressingType.new(node)
      end

      def on_precedencetype(node)
        PrecedenceType.new(node)
      end

      def on_unary_operation(node)
        operator = node.children[0].to_sym
        operand = process(node.children[1])
        UnaryOperation.new(operator, operand, node.token_range)
      end

      def on_binary_operation(node)
        operator = node.children[0].to_sym
        l_operand = process(node.children[1])
        r_operand = process(node.children[2])
        BinaryOperation.new(operator, l_operand, r_operand, node.token_range)
      end

      def on_array(node)
        elements = process_all(node.children)
        List.new(elements, node.token_range)
      end

      def on_range(node)
        elements = process_all(node.children)
        List.new(elements, node.token_range)
      end

      def on_instance_ref_element(node)
        id = process(node.children[0])
        array = process(node.children[1])
        InstanceRefElement.new(id, array, node.token_range)
      end

      def on_instance_ref(node)
        elements = process_all(node.children)
        InstanceRef.new(elements, node.token_range)
      end

      def on_prop_ref(node)
        instance_ref = process(node.children[0])
        prop = process(node.children[1])
        PropRef.new(instance_ref, prop, node.token_range)
      end

      def on_default_prop_assignment(node)
        prop_name, value = process_all(node.children)
        DefaultPropertyAssignment.new(prop_name, value, node.token_range)
      end

      def on_prop_assignment(node)
        id, value = process_all(node.children)
        prop_ref = PropRef.new(nil, id, node.children[0].token_range)
        PropertyAssignment.new(prop_ref, value, node.token_range)
      end

      def on_post_prop_assignment(node)
        prop_ref, value = process_all(node.children)
        PostPropertyAssignment.new(prop_ref, value, node.token_range)
      end

      def on_reset_value(node)
        process(node.children[0])
      end

      def on_address_assignment(node)
        process(node.children[0])
      end

      def on_address_stride(node)
        process(node.children[0])
      end

      def on_address_alignment(node)
        process(node.children[0])
      end

      def on_component_inst(node)
        inst_id = process(node.children[0])
        inst_values =
          [
            :array, :range, :reset_value, :address_assignment, :address_stride, :address_alignment
          ].zip(node.children[1..]).to_h { |k, n| [k, process(n)] }
        ComponentInst.new(inst_id, inst_values, node.token_range)
      end

      def on_component_insts(node)
        insts = process_all(node.children)
        ComponentInsts.new(insts, node.token_range)
      end

      def on_explicit_component_inst(node)
        id = process(node.children[0])
        insts = process(node.children[1])
        ExplicitComponentInst.new(id, insts, node.token_range)
      end

      def on_component_named_def(node)
        id, *elements = process_all(node.children[1..])
        component_definition(node).new(id, elements, nil, node.token_range)
      end

      def on_component_anon_def(node)
        *elements, insts = process_all(node.children[1..])
        component_definition(node).new(nil, elements, insts, node.token_range)
      end

      def on_root(node)
        elements = process_all(node.children)
        Root.new(elements, node.token_range)
      end

      private

      def component_definition(node)
        case node.children[0].to_sym
        when :addrmap then AddrMapDefinition
        when :regfile then RegFileDefinition
        when :reg then RegDefinition
        when :field then FieldDefinition
        end
      end
    end
  end
end
