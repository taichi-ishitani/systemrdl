# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Preprocessor < GeneratedPreprocessor
        def initialize(scanner, debug)
          @scanner = scanner
          @yydebug = debug
          super()
        end

        def parse
          do_parse
        end

        private

        def next_token
          token = @scanner.next_token
          token && [token.kind, token]
        end
      end
    end
  end
end
