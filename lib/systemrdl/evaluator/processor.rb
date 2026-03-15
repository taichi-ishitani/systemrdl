# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Processor < AST::Processor
      def on_id(node)
        node.children[0].to_sym
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

      def on_access_type(node)
        AccessType.new(node)
      end

      def on_on_read_type(node)
        OnReadType.new(node)
      end

      def on_on_write_type(node)
        OnWriteType.new(node)
      end

      def on_addressing_type(node)
        AddressingType.new(node)
      end

      def on_unary_operation(node)
        operator = node.children[0].to_sym
        operand = process(node.children[1])
        UnaryOperation.new(operator, operand, node.range)
      end

      def on_binary_operation(node)
        operator = node.children[0].to_sym
        l_operand = process(node.children[1])
        r_operand = process(node.children[2])
        BinaryOperation.new(operator, l_operand, r_operand, node.range)
      end

      def on_component_inst(node)
        id = process(node.children[0])
        ComponentInst.new(id, node.range)
      end

      def on_component_insts(node)
        insts = process_all(node.children)
        ComponentInsts.new(insts[0].inst_id, insts, node.range)
      end

      def on_component_named_def(node)
        id, *elements = process_all(node.children[1..])
        case node.children[0].to_sym
        when :addrmap then AddrMapDefinition.new(id, elements, nil, node.range)
        end
      end

      def on_component_anon_def(node)
        *elements, insts = process_all(node.children[1..])
        id = insts.component_id
        case node.children[0].to_sym
        when :reg then RegDefinition.new(id, elements, insts, node.range)
        end
      end

      def on_root(node)
        elements = process_all(node.children)
        Root.new(elements, node.range)
      end
    end
  end
end
