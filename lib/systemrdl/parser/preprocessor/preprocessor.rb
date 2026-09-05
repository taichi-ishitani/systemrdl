# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Preprocessor < GeneratedPreprocessor
        class << self
          def process(source, context = nil, remove_eos: false, incdirs: nil, debug: false)
            context ||= Context.new(incdirs, debug)
            scanner = Scanner.new(source)

            __process(scanner, context, remove_eos)
          end

          def process_tokens(tokens, context, remove_eos: false)
            buffer = TokenBuffer.new(tokens)
            __process(buffer, context, remove_eos)
          end

          private

          def __process(scanner, context, remove_eos)
            processor = new(scanner, context.debug).parse

            tokens = []
            processor.process(context, tokens)

            tokens.pop if remove_eos
            tokens
          end
        end

        def initialize(scanner, debug)
          @scanner = scanner
          @yydebug = debug
          @in_macro_body = false
          super()
        end

        def parse
          do_parse
        end

        private

        def next_token
          token = @scanner.next_token(@in_macro_body)
          token && [token.kind, token]
        end

        def enter_macro_body
          @in_macro_body = true
        end

        def exit_macro_body
          @in_macro_body = false
        end

        def collect_list_items(val)
          items = [val[0]]
          val[1].each { |(_comma, item)| items << item }
          items
        end
      end
    end
  end
end
