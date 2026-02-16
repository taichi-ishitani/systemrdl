# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Processor < AST::Processor
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
    end
  end
end
