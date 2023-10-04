# frozen_string_literal: true

module SystemRDL
  module AST
    class PropertyAssignment < Base
      def initialize(position, lhs, rhs, default)
        assign_properties(lhs: lhs, rhs: rhs, default: default)
        super(:property_assignment, position)
      end

      attr_reader :lhs
      attr_reader :rhs

      def default?
        @default
      end
    end

    class PropertyModifier < Base
      def initialize(position, id, modifier, default)
        assign_properties(id: id, modifier: modifier, default: default)
        super(:property_modifier, position)
      end

      attr_reader :id
      attr_reader :modifier

      def default?
        @default
      end
    end
  end
end
