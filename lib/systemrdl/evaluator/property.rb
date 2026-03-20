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
  end
end
