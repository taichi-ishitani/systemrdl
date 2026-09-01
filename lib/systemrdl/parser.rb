# frozen_string_literal: true

module SystemRDL
  module Parser
    def self.parse(code, filename: 'unknown', incdirs: nil, debug: false, test: nil)
      tokens = preprocess(code, filename, incdirs:, debug:)
      parser = Parser.new(tokens, debug, test)
      parser.parse
    end

    def self.preprocess(code, filename, incdirs: nil, debug: false)
      source = Source.new(code, filename, 1, 1)
      Preprocessor::Preprocessor.process(source, incdirs:, debug:)
    end
  end
end
