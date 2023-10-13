# frozen_string_literal: true

module SystemRDL
  module AST
    class Base < ::AST::Node
      def initialize(type, *position_nodes)
        assign_properties(position: extract_position(position_nodes))
        super(type)
      end

      attr_reader :position

      private

      def extract_position(position_nodes)
        position_nodes.compact.flatten.first.position
      end

      def to_symbol(obj)
        case obj
        when Base then obj
        else obj&.to_sym
        end
      end

      def to_array(obj)
        case obj
        when Array then obj
        when Base then [obj]
        end
      end
    end
  end
end
