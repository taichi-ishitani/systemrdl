# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module_function

    def evaluate(ast, **optargs)
      evaluator = build_evaluator(ast)
      evaluator.evaluate(nil, **optargs)
    end

    def build_evaluator(ast)
      Processor.new.process(ast)
    end
  end
end
