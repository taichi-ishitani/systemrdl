# frozen_string_literal: true

module SystemRDL
  module Parser
    def self.parse(code, filename: 'unknown', incdirs: nil, include_limit: 15, debug: false, test: nil)
      tokens = preprocess(code, filename, incdirs:, include_limit:, debug:)
      parser = Parser.new(tokens, debug, test)
      parser.parse
    end

    def self.preprocess(code, filename, incdirs: nil, include_limit: 15, debug: false)
      source = Source.new(code, filename, 1, 1)
      Preprocessor::Preprocessor.process(source, incdirs:, include_limit:, debug:)
    end
  end
end
