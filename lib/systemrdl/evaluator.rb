# frozen_string_literal: true

module SystemRDL
  module Evaluator
    module_function

    def evaluate(ast)
      processor = Processor.new
      result = processor.process(ast)
      result.evaluate
      result
    end
  end
end
