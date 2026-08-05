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
        component_definition = find_component_definition(base, id, **optargs)
        check_recursive_instance(instance, component_definition)
        check_inst_type(component_definition)
        check_instantiable(instance, component_definition)

        @insts.each do |inst|
          inst.evaluate(instance, component_definition, inst_type, **optargs)
        end
      end

      private

      def find_component_definition(base, id, **optargs)
        base.upper_layers(include_self: true).reverse_each do |component|
          definition = component.definitions[id.value]
          next unless definition

          unless optargs[:test] || instantiable_component?(definition)
            message = "#{definition.layer} instance not supported yet"
            raise_evaluation_error message, token_range
          end

          return definition
        end

        raise_evaluation_error "undefined component: #{id.value}", token_range
      end

      def instantiable_component?(definition)
        definition.layer in :addrmap | :regfile | :reg | :field
      end

      def check_recursive_instance(instance, component_definition)
        components = instance.definition.upper_layers(include_self: true)
        return if components.none? { |component| component.equal?(component_definition) }

        message = 'recursive instance not allowed'
        raise_evaluation_error message, token_range
      end

      def check_inst_type(component_definition)
        return if component_definition.support_inst_type?(inst_type)

        message = "#{component_definition.layer} instance with #{inst_type} not allowed"
        raise_evaluation_error message, token_range
      end

      def inst_type
      end

      def check_instantiable(instance, component_definition)
        return if instance.instantiable?(component_definition)

        message = "#{component_definition.layer} instance not allowed in #{instance.layer}"
        raise_evaluation_error message, token_range
      end
    end

    class InternalComponentInsts < ComponentInsts
      private

      def inst_type
        :internal
      end
    end

    class ExternalComponentInsts < ComponentInsts
      private

      def inst_type
        :external
      end
    end

    InstArgs = Data.define(:name, :type, :values)

    class ComponentInst
      include Common

      def initialize(inst_id, inst_values, token_range)
        super(token_range)
        @inst_id = inst_id
        @inst_values = inst_values
      end

      attr_reader :inst_id

      def evaluate(instance, component_definition, inst_type, **optargs)
        inst_values = eval_inst_values(instance, **optargs)
        args = InstArgs.new(@inst_id.value, inst_type, inst_values)
        component_definition.create_instances(instance, args, @token_range, **optargs)
      end

      private

      def eval_inst_values(instance, **optargs)
        @inst_values&.transform_values { |value| value&.evaluate(instance, **optargs) }
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
