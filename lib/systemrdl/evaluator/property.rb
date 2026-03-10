# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Property
      def initialize(instance, name, type)
        @instance = instance
        @name = name
        @type = type
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
