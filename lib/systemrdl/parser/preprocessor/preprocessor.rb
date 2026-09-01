# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Preprocessor < GeneratedPreprocessor
        def self.process(source, context = nil, remove_eos: false, incdirs: nil, debug: false)
          context ||= Context.new(incdirs, debug)

          tokens = []
          processor = new(source, context.debug).parse
          processor.process(context, tokens)

          remove_eos ? tokens[..-2] : tokens
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
