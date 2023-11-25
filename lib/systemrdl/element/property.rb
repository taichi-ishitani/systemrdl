# frozen_string_literal: true

module SystemRDL
  module Element
    class Property
      def initialize(component, name, type, ref_target, dynamic_assign)
        @component = component
        @name = name
        @type = Array(type)
        @ref_target = ref_target
        @dynamic_assign = dynamic_assign
      end

      attr_reader :component
      attr_reader :name
      attr_reader :type
      attr_reader :value

      def ref_target?
        return false if @ref_target.nil?

        @ref_target
      end

      def dynamic_assign?
        return false if @dynamic_assign.nil?

        @dynamic_assign
      end

      def assigned_from?(scope)
        @performed_scope&.any?(&scope.method(:equal?))
      end

      def assign_value(value, scope)
        (@performed_scope ||= []) << scope if scope
        @value = value
      end
    end

    class PropertyDefinition
      def initialize(name)
        @name = name
        yield(self)
      end

      attr_setter :target
      attr_setter :type
      attr_setter :ref_target
      attr_setter :dynamic_assign
      attr_setter :value

      def match_target?(component_type)
        Array(@target).include?(component_type)
      end

      def create(component)
        property = Property.new(component, @name, @type, @ref_target, @dynamic_assign)
        property.assign_value(@value, nil)
        property
      end
    end
  end
end
