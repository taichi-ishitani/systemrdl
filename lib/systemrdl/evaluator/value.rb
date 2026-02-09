# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Value
      def initialize(type, node)
        @type = type
        @node = node
      end

      attr_reader :type
      attr_reader :value
    end

    class Boolean < Value
      def initialize(node)
        super(node.type, node)
      end

      def evaluate
        @value = @node.children[0].text == 'true'
      end
    end
  end
end
