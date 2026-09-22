# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module PropertyAssignmentCommon
      def initialize(value, token_range)
        super(token_range)
        @value = value
      end

      def evaluate(instance, **optargs)
        properties = find_properties(instance)
        check_properties(instance, properties)

        properties.each do |property|
          value = eval_value(instance, property, **optargs)
          assign_property(instance, property, value)
        end
      end

      private

      def check_properties(_instance, _properties)
      end

      def eval_value(instance, property, **optargs)
        value =
          if @value
            @value.evaluate(instance, **optargs)
          else
            # true value is implicitly applied
            # when the assignment value is omitted.
            Value.new(true, :boolean, 1, @token_range)
          end

        coerce_value(property, value)
      end

      def coerce_value(property, value)
        value = value.coerce(property.types) do
          message =
            "#{value.type} type not supported by #{property.name} property: " \
            "expected #{type_label(property)}"
          raise_evaluation_error message, @token_range
        end
        check_value(property, value)

        value
      end

      def type_label(property)
        types = property.types
        if types.size == 1
          types[0]
        else
          [types[..-2].join(', '), types[-1]].join(' or ')
        end
      end

      def check_value(property, value)
      end
    end

    class PropertyAssignment
      include Common
      include PropertyAssignmentCommon

      def initialize(prop_ref, value, token_range)
        super(value, token_range)
        @prop_ref = prop_ref
      end

      private

      def find_properties(instance)
        @prop_ref.find(instance, allow_array_ref: false)
      end

      def check_properties(_instance, properties)
        property = properties[0]
        return unless property&.assigned?

        message = "#{property.name} already assigned in this scope"
        raise_evaluation_error message, token_range
      end

      def assign_property(_instance, property, value)
        property.assign(value)
      end
    end

    class PostPropertyAssignment
      include Common
      include PropertyAssignmentCommon

      def initialize(prop_ref, value, token_range)
        super(value, token_range)
        @prop_ref = prop_ref
      end

      private

      def check_value(_property, value)
        check_ref_target(value)
      end

      def check_ref_target(value)
        return if value.type != :property_reference

        property = value.value
        return if property.ref_target?

        message = "reference to #{property.name} property not allowed"
        raise_evaluation_error message, @token_range
      end

      def find_properties(instance)
        @prop_ref.find(instance, allow_array_ref: true)
      end

      def check_properties(_instance, properties)
        properties.each do |property|
          next unless property

          unless property.dynamic_assign?
            message = "dynamic assignment to #{property.name} property not allowed"
            raise_evaluation_error message, token_range
          end

          if !property.per_element_assign? && @prop_ref.array_select?
            message = "element assignment to #{property.name} property not allowed"
            raise_evaluation_error message, token_range
          end
        end
      end

      def assign_property(_instance, property, value)
        property.assign(value)
      end
    end

    class DefaultPropertyAssignment
      include Common
      include PropertyAssignmentCommon

      def initialize(prop_name, value, token_range)
        super(value, token_range)
        @prop_name = prop_name
      end

      private

      def find_properties(_instance)
        prop_def = BuiltinProperties.find(@prop_name.value)
        return [prop_def] if prop_def

        message = "undefined property: #{@prop_name.value}"
        raise_evaluation_error message, token_range
      end

      def assign_property(instance, _property, value)
        definition = instance.definition
        definition.assign_default_property(@prop_name.value, value, token_range)
      end
    end
  end
end
