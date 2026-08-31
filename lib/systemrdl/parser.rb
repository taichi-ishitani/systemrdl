# frozen_string_literal: true

module SystemRDL
  module Parser
    def self.parse(code, filename: 'unknown', debug: false, test: nil)
      tokens = preprocess(code, filename, debug:)
      parser = Parser.new(tokens, debug, test)
      parser.parse
    end

    def self.preprocess(code, filename, debug: false)
      source = Source.new(code, filename, 1, 1)
      Preprocessor::Preprocessor.process(source, debug:)
    end
  end
end
