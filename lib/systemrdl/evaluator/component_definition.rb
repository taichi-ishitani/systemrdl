# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentDefinition
      def initialize(id, elements, range)
        @id = id
        @definitions = []
        @elements = elements
        @range = range
        @elements.each do |element|
          element.set_parent(self)
        end
      end

      def set_parent(node)
        @parent = node
        @parent.definitions << self
      end

      def create_instance(parent_instance, name, **optargs)
        parent_instance.add_child_instance(name) do |instance|
          init_properties(instance)
          @elements.each do |element|
            element.evaluate(instance, **optargs)
          end
        end
      end

      private

      def init_properties(instance)
        #
        # Table 5—Universal component properties
        #
        create_property(instance, :name, :string, instance.name.to_s)
        create_property(instance, :desc, :string, '')
      end

      def create_property(instance, name, type, value)
        property = Property.new(instance, name, type, value)
        instance.properties << property
      end

      protected

      attr_reader :definitions
    end

    class Root < ComponentDefinition
      def initialize(elements, range)
        super(:root, elements, range)
      end

      def evaluate(instance, **optargs)
        @elements.each do |element|
          element.evaluate(instance, **optargs)
        end
      end
    end

    class AddrMapDefinition < ComponentDefinition
      def evaluate(instance, **optargs)
        create_instance(instance, @id, **optargs)
      end

      private

      def init_properties(instance)
        super

        #
        # Table 26—Address map properties
        #
        create_property(instance, :alignment, :longint, nil)
        create_property(instance, :sharedextbus, :boolean, false)
        create_property(instance, :errextbus, :boolean, false)
        create_property(instance, :bigendian, :boolean, false)
        create_property(instance, :littleendian, :boolean, false)
        create_property(instance, :addressing, :addressingtype, :regalign)
        create_property(instance, :rsvdset, :boolean, false)
        create_property(instance, :rsvdsetX, :boolean, false)
        create_property(instance, :msb0, :boolean, false)
        create_property(instance, :lsb0, :boolean, false)
      end
    end
  end
end
