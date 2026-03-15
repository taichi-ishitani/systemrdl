# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentInsts
      include Common

      def initialize(component_id, insts, range)
        super(range)
        @component_id = component_id
        @insts = insts
      end

      attr_reader :component_id

      def connect(parent, component)
        super
        @insts.each { |inst| inst.connect(self, component) }
      end

      def evaluate(instance, **optargs)
        component_definition = find_component_definition
        @insts.each do |inst|
          inst.evaluate(instance, component_definition:, **optargs)
        end
      end

      private

      def find_component_definition
        component = @component
        while component
          definition = component.definitions[@component_id]
          return definition if definition

          component = component.component
        end

        # TODO
        # report error
      end
    end

    class ComponentInst
      include Common

      def initialize(inst_id, range)
        super(range)
        @inst_id = inst_id
      end

      attr_reader :inst_id

      def evaluate(instance, component_definition:, **optargs)
        component_definition.create_instance(instance, @inst_id, **optargs)
      end
    end
  end
end
