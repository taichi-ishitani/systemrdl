# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module PropertyAssignmentCommon
      def initialize(value, token_range)
        super(token_range)
        @value = value
      end

      def evaluate(instance, **optargs)
        property = find_property(instance, **optargs)
        value = eval_value(instance, property, **optargs)
        assign_property(instance, property, value)
      end

      private

      def eval_value(instance, property, **optargs)
        value =
          if @value
            @value.evaluate(instance, **optargs)
          else
            # true value is implicitly applied
            # when the assignment value is omitted.
            Value.new(true, :boolean, 1, @token_range)
          end
        check_value(property, value)

        if match_integral_type?(property, value)
          cast_integral_value(property, value)
        else
          value
        end
      end

      def check_value(property, value)
        check_type_compatibility(property, value)
      end

      def check_type_compatibility(property, value)
        return if property.types.include?(value.type) || match_integral_type?(property, value)

        message =
          "#{value.type} type not supported by #{property.name} property: " \
          "expected #{type_label(property)}"
        raise_evaluation_error message, @token_range
      end

      def type_label(property)
        types = property.types
        if types.size == 1
          types[0]
        else
          [types[..-2].join(', '), types[-1]].join(' or ')
        end
      end

      def match_integral_type?(property, value)
        integral_types = [:bit, :longint, :boolean]
        return false unless integral_types.include?(value.type)

        (integral_types & property.types).any?
      end

      def cast_integral_value(property, value)
        if property.types.include?(:bit)
          to_bit(value)
        elsif property.types.include?(:longint)
          to_longint(value)
        else
          to_boolean(value)
        end
      end

      def to_bit(value)
        return value if value.type == :bit

        if value.type == :longint
          Value.new(value.value, :bit, 64, value.token_range)
        elsif value.value
          Value.new(1, :bit, 1, value.token_range)
        else
          Value.new(0, :bit, 1, value.token_range)
        end
      end

      def to_longint(value)
        return value if value.type == :longint

        if value.type == :bit
          v = value.value & 0xFFFF_FFFF_FFFF_FFFF
          Value.new(v, :longint, 64, value.token_range)
        elsif value.value
          Value.new(1, :longint, 64, value.token_range)
        else
          Value.new(0, :longint, 64, value.token_range)
        end
      end

      def to_boolean(value)
        return value if value.type == :boolean

        Value.new(value.value != 0, :boolean, 1, value.token_range)
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

      def find_property(instance, **optargs)
        property = @prop_ref.find(instance, **optargs)
        if property&.assigned?
          message = "#{property.name} already assigned in this scope"
          raise_evaluation_error message, token_range
        end

        property
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

      def find_property(instance, **optargs)
        property = @prop_ref.find(instance, **optargs)
        if property && !property.dynamic_assign?
          message = "dynamic assignment to #{property.name} property not allowed"
          raise_evaluation_error message, token_range
        end

        property
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

      def find_property(_instance, **_optargs)
        prop_def = BuiltinProperties.find(@prop_name.value)
        return prop_def if prop_def

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
