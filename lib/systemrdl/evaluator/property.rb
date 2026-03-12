# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Property
      def initialize(instance, name, type, value)
        @instance = instance
        @name = name
        @type = type
        @value = value
      end

      attr_reader :name
      attr_reader :type
      attr_reader :value

      def assign(value)
        @value = value
      end
    end
  end
end
