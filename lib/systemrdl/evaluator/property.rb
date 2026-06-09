# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Property
      def initialize(instance, name, types, value)
        @instance = instance
        @name = name
        @types = types
        @value = value
      end

      attr_reader :name
      attr_reader :types
      attr_reader :value

      def assign(value)
        @value = value
      end
    end

    class PropertyAssignment
      include Common

      def initialize(prop_ref, value, token_range)
        super(token_range)
        @prop_ref = prop_ref
        @value = value
      end

      def evaluate(instance, **_optargs)
        property = @prop_ref.find(instance)
        property.assign(@value.to_value)
      end
    end

    class PostPropertyAssignment
      include Common

      def initialize(prop_ref, value, token_range)
        super(token_range)
        @prop_ref = prop_ref
        @value = value
      end

      def evaluate(instance, **_optargs)
        property = @prop_ref.find(instance)
        property.assign(@value.to_value)
      end
    end
  end
end
