# frozen_string_literal: true

module SystemRDL
  module Parser
    module_function

    def parse(code, filename: 'unknown', debug: false, test: false)
      scanner = Scanner.new(code, filename)
      parser = Parser.new(scanner, debug:, test:)
      parser.parse
    end
  end
end
