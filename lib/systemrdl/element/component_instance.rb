# frozen_string_literal: true

module SystemRDL
  module Element
    class ComponentInstance
      def initialize(parent, instance_name, array, position = nil)
        @parent = parent
        @instance_name = instance_name
        @array = array
        @position = position
        block_given? && yield(self)
      end

      attr_reader :parent
      attr_reader :instance_name
      attr_reader :array
      attr_reader :position

      def components
        @components ||= []
      end

      def add_component(component)
        components << component
      end

      def properties
        @properties ||= []
      end

      def add_property(property)
        properties << property
      end
    end
  end
end
