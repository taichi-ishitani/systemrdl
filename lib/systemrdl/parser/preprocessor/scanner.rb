# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Scanner
        include RaiseParseError

        def initialize(source)
          @source = source
          @control_tokens = []
        end

        def next_token
          if @control_tokens.empty?
            skip_blank
            push_eos_tokens if eos?
          end

          if @control_tokens.empty?
            scan_next_token
          else
            @control_tokens.shift
          end
        end

        private

        def eos?
          @source.eos?
        end

        def skip_blank
          loop do
            next if scan(Patterns::WHITE_SPACES)
            next if scan(Patterns::LINE_COMMENT)
            next if scan_block_comment

            break
          end
        end

        def scan_block_comment
          comment = scan(Patterns::BLOCK_COMMENT)
          return comment if comment

          if (_, pos = scan(Patterns::UNTERMINATED_BLOCK_COMMENT))
            raise_parse_error 'unterminated block comment', pos
          end
        end

        def push_eos_tokens
          @control_tokens << create_control_token(:EOS)
          @control_tokens << nil
        end

        def scan(pattern)
          @source.scan(pattern)
        end

        def scan_token(kind, pattern)
          text, pos = scan(pattern)
          text && Token.new(text, kind, pos)
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

        def create_control_token(kind)
          Token.new('', kind, @source.position)
        end

        def scan_next_token
          token =
            scan_directive || scan_string || scan_number || scan_symbol || scan_word
          return token if token

          char = peek_char
          raise_parse_error "illegal character `#{char}`", @source.position
        end

        def scan_directive
          text, pos = scan(/`[_a-zA-Z]\w*/)
          return unless text

          Patterns::DIRECTIVES.each do |pattern, kind|
            next if text != pattern

            token = Token.new(text, kind, pos)
            return token
          end

          Token.new(text, :PP_MACRO_ID, pos)
        end

        def scan_string
          return unless peek(/"/)

          pos = @source.position
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
          Token.new(text, :STRING, pos)
        end

        def scan_number
          Patterns::NUMBERS.each do |pattern, kind|
            token = scan_token(kind, pattern)
            return token if token
          end

          nil
        end

        def scan_symbol
          Patterns::SYMBOLS.each do |pattern, kind|
            token = scan_token(kind, pattern)
            return token if token
          end

          nil
        end

        def scan_word
          text, pos = scan(/[_a-zA-Z]\w*/)
          return unless text

          Patterns::KEYWORDS.each do |pattern, kind|
            next if text != pattern

            token = Token.new(text, kind, pos)
            return token
          end

          Token.new(text, :SIMPLE_ID, pos)
        end
      end
    end
  end
end
