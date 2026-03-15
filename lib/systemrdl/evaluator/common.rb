# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module Common
      include RaiseEvaluationError

      def initialize(range)
        @range = range
      end

      attr_reader :range
      attr_reader :parent
      attr_reader :component

      def connect(parent, component)
        @parent = parent
        @component = component
      end
    end
  end
end
