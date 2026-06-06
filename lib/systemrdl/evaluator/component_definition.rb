# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentDefinition
      include Common

      def initialize(id, elements, insts, token_range)
        super(token_range)
        @id = id
        @definitions = {}
        @elements = elements
        @insts = insts
      end

      attr_reader :id
      attr_reader :definitions

      def connect(parent, component)
        super
        @component.add_definition(self)
        @elements.each { |element| element.connect(self, self) }
        @insts&.connect(self, self)
      end

      def evaluate(instance, **optargs)
        @insts&.evaluate(instance, **optargs)
      end

      def create_instance(parent_instance, name, **optargs)
        instance = instnace_class.new(parent_instance, name)
        parent_instance.instances << instance

        init_instance(instance)
        @elements.each { |element| element.evaluate(instance, **optargs) }

        instance
      end

      private

      def init_instance(instance)
        init_properties(instance)
      end

      def init_properties(instance)
        #
        # Table 5—Universal component properties
        #
        create_property(instance, :name, [:string], instance.name.to_s)
        create_property(instance, :desc, [:string], '')
      end

      def create_property(instance, name, types, value)
        property = Property.new(instance, name, types, value)
        instance.properties << property
      end

      protected

      def add_definition(definition)
        id = definition.id
        @definitions[id] = definition
      end
    end
  end
end
