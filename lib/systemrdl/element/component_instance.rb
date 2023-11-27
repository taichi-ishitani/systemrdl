# frozen_string_literal: true

module SystemRDL
  module Element
    class ComponentInstance
      def initialize(root, parent, instance_name, array, position = nil)
        @parent = parent
        @instance_name = instance_name
        @array = array
        @position = position
        build_properties(root)
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

      private

      def build_properties(root)
        root.property_definitions.each do |definition|
          definition.match_target?(component_type) &&
            add_property(definition.create(self))
        end
      end

      def component_type
      end
    end

    class RootInstance < ComponentInstance
      class << self
        def builtin_property_definitions
          @builtin_property_definitions ||= []
        end

        def define_builtin_property(name, &block)
          builtin_property_definitions << PropertyDefinition.new(name, &block)
        end
      end

      def initialize(instance_name)
        super(self, instance_name, nil, nil)
      end

      def property_definitions
        self.class.builtin_property_definitions
      end

      private

      def component_type
        :root
      end
    end

    class FieldInstance < ComponentInstance
      private

      def component_type
        :field
      end
    end

    class RegInstance < ComponentInstance
      private

      def component_type
        :reg
      end
    end

    class RegfileInstance < ComponentInstance
      private

      def component_type
        :regfile
      end
    end
  end
end
