# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentDefinition
      include Common

      def initialize(id, param_def, elements, insts, token_range)
        super(token_range)
        @id = id || insts.insts[0].inst_id
        @anonymous_def = id.nil?
        @definitions = {}
        @param_def = param_def
        @elements = elements
        @insts = insts
      end

      attr_reader :id
      attr_reader :param_def
      attr_reader :definitions
      attr_reader :current_inst

      def anonymous_def?
        @anonymous_def
      end

      def connect(parent, component)
        super
        @component&.add_definition(self)
        @elements.each { |element| element.connect(self, self) }
        @insts&.connect(self, self)
      end

      def upper_layers(include_root: true, include_self: false)
        if layer == :root
          (include_root && [self]) || []
        else
          layers = component.upper_layers(include_root:, include_self: true)
          layers << self if include_self
          layers
        end
      end

      def component_name?(name)
        @definitions.key?(name)
      end

      def evaluate(instance, **optargs)
        check_definable(instance)
        @insts&.evaluate(instance, @parent, @id, **optargs)
      end

      def create_instances(parent_instance, inst_args, token_range, **optargs)
        eval_array(inst_args.values) do |array_info|
          create_instance(parent_instance, inst_args, array_info, token_range, **optargs)
        end
      end

      def validate(_instance)
      end

      def revalidate(_instance)
      end

      def finalize(_instance)
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

      def create_instance(parent_instance, inst_args, array_info, token_range, **optargs)
        unless unique_instance?(parent_instance, inst_args.name, array_info)
          message = "duplicated instance: #{inst_args.name}"
          raise_evaluation_error message, token_range
        end

        instance = new_instance(parent_instance, inst_args, token_range)
        build_instance(instance, inst_args, array_info, **optargs)

        parent_instance&.add_instance(instance)
        instance
      end

      def unique_instance?(parent_instance, inst_name, array_info)
        return false if duplicated_inst?(inst_name, array_info, parent_instance&.params)
        return false if duplicated_inst?(inst_name, array_info, parent_instance&.instances)

        true
      end

      def duplicated_inst?(inst_name, array_info, elements)
        return false unless elements

        elements.any? do |element|
          if element.name != inst_name
            false
          elsif element.array? && array_info
            element.array_info.id != array_info.id
          else
            true
          end
        end
      end

      def new_instance(parent_instance, inst_args, token_range)
        instance_class.new(self, parent_instance, inst_args.name, token_range)
      end

      def build_instance(instance, inst_args, array_info, **optargs)
        @current_inst = instance

        apply_param_values(instance, @param_def, inst_args.param_inst, **optargs)
        init_properties(instance)
        eval_body(instance, **optargs)
        apply_array(instance, array_info)
        apply_inst_values(instance, inst_args.values)
        apply_inst_type(instance, inst_args.type)
        post_build(instance)
        instance.validate

        @current_inst = nil unless instance.root?
        instance.clear_default_properties

        instance
      end

      def apply_param_values(instance, param_def, param_inst, **optargs)
        param_def&.evaluate(instance, param_inst, **optargs)
      end

      def init_properties(instance)
        return if instance.root?

        BuiltinProperties.init_properties(instance.layer, instance)
      end

      def eval_body(instance, **optargs)
        @elements.each { |element| element.evaluate(instance, **optargs) }
      end

      def apply_inst_type(_instance, _inst_type)
      end

      def apply_inst_values(_instance, _inst_values)
      end

      def apply_array(_instance, _array_info)
      end

      def post_build(_instance)
      end

      protected

      def add_definition(definition)
        id = definition.id.value
        if component_name?(id)
          message = "duplicated component identifier: #{id}"
          raise_evaluation_error message, definition.token_range
        end

        @definitions[id] = definition
      end
    end
  end
end
