# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class ComponentDefinition
      include Common

      def initialize(id, param_def, elements, insts, token_range)
        super(token_range)
        @id = id || insts.insts[0].inst_id
        @definitions = {}
        @param_def = param_def
        @elements = elements
        @insts = insts
        @default_properties = {}
      end

      attr_reader :id
      attr_reader :param_def
      attr_reader :definitions

      def connect(parent, component)
        super
        @component&.add_definition(self)
        @elements.each { |element| element.connect(self, self) }
        @insts&.connect(self, self)
      end

      def upper_layers(include_self: false)
        layers = (layer == :root && []) || component.upper_layers(include_self: true)
        layers << self if include_self
        layers
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

      def assign_default_property(name, value, token_range)
        if @default_properties.key?(name)
          message = "#{name} already assigned in this scope"
          raise_evaluation_error message, token_range
        end

        @default_properties[name] = value
      end

      def find_default_property(name)
        upper_layers.reverse_each do |component|
          if (prop = component.default_properties[name])
            return prop
          end
        end

        nil
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

        instance = instance_class.new(self, parent_instance, inst_args.name, token_range)

        apply_param_values(instance, @param_def, inst_args.param_inst, **optargs)
        init_properties(instance)
        eval_body(instance, **optargs)
        apply_array(instance, array_info)
        apply_inst_values(instance, inst_args.values)
        apply_inst_type(instance, inst_args.type)
        post_build(instance)
        instance.validate

        parent_instance.instances << instance if parent_instance
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

      def apply_param_values(instance, param_def, param_inst, **optargs)
        param_def&.evaluate(instance, param_inst, **optargs)
      end

      def init_properties(instance)
        prop_defs = BuiltinProperties.properties
        prop_defs.each do |prop_def|
          prop = prop_def.create(instance)
          next unless prop

          instance.properties << prop
        end
      end

      def eval_body(instance, **optargs)
        @default_properties.clear
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
        if @definitions.key?(id)
          message = "duplicated component: #{id}"
          raise_evaluation_error message, definition.token_range
        end

        @definitions[id] = definition
      end

      attr_reader :default_properties
    end
  end
end
