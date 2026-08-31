# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Preprocessor < GeneratedPreprocessor
        def self.process(source, debug: false)
          processor = new(source, debug).parse

          context = Context.new
          tokens = []
          processor.process(context, tokens)

          tokens
        end

        def initialize(source, debug)
          @scanner = Scanner.new(source)
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
