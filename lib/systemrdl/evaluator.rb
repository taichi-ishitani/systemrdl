# frozen_string_literal: true

module SystemRDL
  module Evaluator
    def self.evaluate(ast, root = nil, **optargs)
      evaluator = build_evaluator(ast)
      evaluator.evaluate(root, **optargs)
    end

    def self.build_evaluator(ast)
      Processor.new.process(ast)
    end
  end
end
