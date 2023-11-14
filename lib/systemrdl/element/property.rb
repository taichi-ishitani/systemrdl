# frozen_string_literal: true

module SystemRDL
  module Element
    class Property
      def initialize(component, name, type, ref_target, dynamic_assignable)
        @component = component
        @name = name
        @type = Array(type)
        @ref_target = ref_target
        @dynamic_assignable = dynamic_assignable
      end

      attr_reader :component
      attr_reader :name
      attr_reader :type
      attr_reader :value

      def ref_target?
        @ref_target
      end

      def dynamic_assignable?
        @dynamic_assignable
      end

      def assigned_from?(scope)
        @performed_scope&.any?(&scope.method(:equal?))
      end

      def assign_value(value, scope)
        (@performed_scope ||= []) << scope
        @value = value
      end
    end
  end
end
