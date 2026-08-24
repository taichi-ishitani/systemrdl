# frozen_string_literal: true

module SystemRDL
  module Parser
    module Processor
      class Base
        include RaiseParseError

        def initialize(source, filename)
          @source = source
          @filename = filename
        end

        attr_reader :filename

        def line
          @source.line
        end

        def column
          @source.column
        end

        def eos?
          @source.eos?
        end

        def skip_blank
          loop do
            next if scan(Pattern::WHITE_SPACES)
            next if scan(Pattern::LINE_COMMENT)
            next if scan_block_comment

            break
          end
        end

        def next_token
          scan_next_token
        end

        private

        def scan_block_comment
          comment = scan(Pattern::BLOCK_COMMENT)
          return comment if comment

          if (_, line, column = scan(Pattern::UNTERMINATED_BLOCK_COMMENT))
            pos = Position.new(@filename, line, column)
            raise_parse_error 'unterminated block comment', pos
          end
        end

        def scan_next_token
          token =
            scan_string || scan_number || scan_symbol || scan_word
          return token if token

          char = peek_char
          pos = Position.new(@filename, @line, @column)
          raise_parse_error "illegal character `#{char}`", pos
        end

        def scan_string
          return unless peek(/"/)

          line = @line
          column = @column

          buffer = []
          while (char = peek_char)
            advance(char)
            if char == '\\' && ((next_char, _, _) = scan(/"/))
              buffer << next_char
            else
              buffer << char
              break if buffer.size >= 2 && buffer.last == '"'
            end
          end

          text = buffer.join
          Token.create(:STRING, text, @filename, line, column)
        end

        def scan_number
          Pattern::NUMBERS.each do |pattern, kind|
            token = scan_token(kind, pattern)
            return token if token
          end

          nil
        end

        def scan_symbol
          Pattern::SYMBOLS.each do |pattern, kind|
            token = scan_token(kind, pattern)
            return token if token
          end

          nil
        end

        def scan_word
          text, line, column = scan(/[_a-zA-Z]\w*/)
          return unless text

          Pattern::KEYWORDS.each do |pattern, kind|
            next if text != pattern

            token = Token.create(kind, text, @filename, line, column)
            return token
          end

          Token.create(:SIMPLE_ID, text, @filename, line, column)
        end

        def scan(pattern)
          @source.scan(pattern)
        end

        def scan_token(kind, pattern)
          text, line, column = scan(pattern)
          text && Token.create(kind, text, @filename, line, column)
        end

        def peek(pattern)
          @source.peek(pattern)
        end

        def peek_char
          peek(/./m)
        end

        def advance(text)
          @source.advance(text)
        end
      end

      class Default < Base
      end
    end
  end
end
