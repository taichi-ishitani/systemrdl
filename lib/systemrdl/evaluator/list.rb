# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class List
      include Common

      def initialize(elements, token_range)
        @elements = elements
        @token_range = token_range
      end

      attr_reader :elements
      attr_reader :token_range

      def evaluate(instance, **optargs)
        elements = @elements.map { |element| element.evaluate(instance, **optargs) }
        List.new(elements, @token_range)
      end

      def size
        @elements.size
      end
    end
  end
end
