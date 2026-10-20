# frozen_string_literal: true

module SystemRDL
  module Evaluator
    def self.evaluate(ast, root = nil, ifmissing: nil, **optargs)
      evaluator = build_evaluator(ast, ifmissing:)
      evaluator.evaluate(root, **optargs)
    end

    def self.build_evaluator(ast, ifmissing: nil)
      Processor.new(ifmissing).process(ast)
    end
  end
end
