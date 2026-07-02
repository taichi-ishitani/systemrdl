# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentDefinition
      include Common

      def initialize(id, elements, insts, token_range)
        super(token_range)
        @id = id || insts.insts[0].inst_id
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
        check_definable(instance)
        @insts&.evaluate(instance, @parent, @id, **optargs)
      end

      def create_instances(parent_instance, inst_name, inst_values, token_range, **optargs)
        eval_array(inst_values) do |array_indices, array_sizes|
          create_instance(
            parent_instance, inst_name, inst_values,
            array_indices, array_sizes, token_range, **optargs
          )
        end
      end

      def validate(_instance)
      end

      def revalidate(_instance)
      end

      private

      def check_power_of_2(instance, name, min_value)
        value = instance.property_value(name)
        return unless value

        return if power_of_2?(value.value, min_value)

        message = "#{name} must be a power of 2: #{value}"
        raise_evaluation_error message, value.token_range
      end

      def power_of_2?(value, min_value)
        value >= min_value && value.nobits?(value - 1)
      end

      def check_property_exclusivity(instance, names)
        properties =
          names
            .map { |name| instance.property_value(name) }
            .select { |v| v&.value }
        return if properties.size <= 1

        labels = [names[..-2].join(', '), names[-1]].join(' and ')
        message = "#{labels} properties are mutually exclusive"

        raise_evaluation_error message, *properties.map(&:token_range)
      end

      def check_definable(instance)
        return if instance.definable?(self)

        message = "#{layer} definition not allowed in #{instance.layer}"
        raise_evaluation_error message, token_range
      end

      def eval_array(_inst_values)
        yield(nil, nil)
      end

      def create_instance(parent_instance, inst_name, inst_values, array_indices, array_sizes, token_range, **optargs)
        instance = instance_class.new(self, parent_instance, inst_name, array_indices, array_sizes, token_range)

        init_properties(instance)
        eval_body(instance, **optargs)
        apply_inst_values(instance, inst_values)
        post_build(instance)
        instance.validate

        parent_instance.instances << instance if parent_instance
        instance
      end

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

      def post_build(_instance)
      end

      protected

      def add_definition(definition)
        id = definition.id.value
        @definitions[id] = definition
      end
    end
  end
end
