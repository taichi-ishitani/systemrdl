# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentInsts
      include Common

      def initialize(insts, token_range)
        super(token_range)
        @insts = insts
      end

      attr_reader :insts

      def connect(parent, component)
        super
        @insts.each { |inst| inst.connect(self, component) }
      end

      def evaluate(instance, base, id, **optargs)
        component_definition = find_component_definition(base, id)
        check_instantiable(instance, component_definition)

        @insts.each do |inst|
          inst.evaluate(instance, component_definition, **optargs)
        end
      end

      private

      def find_component_definition(base, id)
        component = base
        while component
          definition = component.definitions[id.value]
          return definition if definition

          component = component.component
        end

        # TODO
        # report error
      end

      def check_instantiable(instance, component_definition)
        return if instance.instantiable?(component_definition)

        message = "#{component_definition.layer} instance not allowed in #{instance.layer}"
        raise_evaluation_error message, token_range
      end
    end

    class ComponentInst
      include Common

      def initialize(inst_id, inst_values, token_range)
        super(token_range)
        @inst_id = inst_id
        @inst_values = inst_values
      end

      attr_reader :inst_id

      def evaluate(instance, component_definition, **optargs)
        component_definition.create_instance(instance, @inst_id.value, @inst_values, **optargs)
      end
    end

    class ExplicitComponentInst
      include Common

      def initialize(id, insts, token_range)
        super(token_range)
        @id = id
        @insts = insts
      end

      def connect(parent, component)
        super
        @insts.connect(self, component)
      end

      def evaluate(instance, **optargs)
        @insts.evaluate(instance, @component, @id, **optargs)
      end
    end
  end
end
