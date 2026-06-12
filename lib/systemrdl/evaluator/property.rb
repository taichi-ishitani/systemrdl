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

    module PropertyAssignmentCommon
      def initialize(prop_ref, value, token_range)
        super(token_range)
        @prop_ref = prop_ref
        @value = value
      end

      def evaluate(instance, **_optargs)
        property = @prop_ref.find(instance)
        value =
          if @value
            @value.to_value
          else
            # true value is implicitly applied
            # when the assignment value is omitted.
            Value.new(true, @token_range)
          end
        property.assign(value)
      end
    end

    class PropertyAssignment
      include Common
      include PropertyAssignmentCommon
    end

    class PostPropertyAssignment
      include Common
      include PropertyAssignmentCommon
    end
  end
end
