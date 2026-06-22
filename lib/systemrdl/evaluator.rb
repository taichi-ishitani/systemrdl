# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module_function

    def evaluate(ast)
      evaluator = build_evaluator(ast)
      evaluator.evaluate(nil)
    end

    def build_evaluator(ast)
      Processor.new.process(ast)
    end
  end
end
