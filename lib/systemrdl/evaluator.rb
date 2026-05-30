# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module_function

    def evaluate(ast)
      root = RootInstance.new
      evaluator = build_evaluator(ast)
      evaluator.evaluate(root)
      root
    end

    def build_evaluator(ast)
      Processor.new.process(ast)
    end
  end
end
