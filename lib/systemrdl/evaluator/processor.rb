# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Processor < AST::Processor
      def on_boolean(node)
        Boolean.new(node)
      end
    end
  end
end
