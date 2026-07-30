# frozen_string_literal: true

module SystemRDL
  module Parser
    def self.parse(code, filename: 'unknown', debug: false, test: nil)
      scanner = Scanner.new(code, filename, test)
      parser = Parser.new(scanner, debug:)
      parser.parse
    end
  end
end
