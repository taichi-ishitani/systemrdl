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

      def create_instance(parent_instance, inst_name, inst_values, **optargs)
        instance = instnace_class.new(parent_instance, inst_name)

        init_properties(instance)
        eval_body(instance, **optargs)
        apply_inst_values(instance, inst_values)
        validate(instance)

        parent_instance.instances << instance
        instance
      end

      private

      def init_properties(instance)
        #
        # Table 5—Universal component properties
        #
        create_property(instance, :name, [:string], instance.name.to_s)
        create_property(instance, :desc, [:string], '')
      end

      def create_property(instance, name, types, value)
        value = Value.new(value, nil) unless value.nil?
        property = Property.new(instance, name, types, value)
        instance.properties << property
      end

      def eval_body(instance, **optargs)
        @elements.each { |element| element.evaluate(instance, **optargs) }
      end

      def apply_inst_values(_instance, _inst_values)
      end

      def validate(_instance)
      end

      protected

      def add_definition(definition)
        id = definition.id.value
        @definitions[id] = definition
      end
    end
  end
end
