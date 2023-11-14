# frozen_string_literal: true

module SystemRDL
  module AST
    class PropertyAssignment < Base
      def initialize(lhs, rhs, default)
        assign_properties(lhs: lhs, rhs: rhs, default: !default.nil?)
        super(:property_assignment, default, lhs)
      end

      attr_reader :lhs
      attr_reader :rhs

      def default?
        @default
      end

      def dynamic_assignment?
        lhs.instance_refernce && lhs.property && true || false
      end
    end

    class PropertyModifier < Base
      def initialize(id, modifier, default)
        assign_properties(id: id, modifier: modifier.to_sym, default: !default.nil?)
        super(:property_modifier, default, modifier)
      end

      attr_reader :id
      attr_reader :modifier

      def default?
        @default
      end
    end
  end
end
