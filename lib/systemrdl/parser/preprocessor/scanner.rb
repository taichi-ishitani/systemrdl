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

        def next_token(in_macro_body)
          if @control_tokens.empty?
            skip_blank(in_macro_body)
            push_eos_tokens if eos?
          end

          if @control_tokens.empty?
            scan_next_token(in_macro_body)
          else
            @control_tokens.shift
          end
        end

        private

        def eos?
          @source.eos?
        end

        def skip_blank(in_macro_body)
          loop do
            next if scan(Patterns::WHITE_SPACES)
            next if !in_macro_body && scan(Patterns::NL)
            next if scan_line_comment(in_macro_body)
            next if scan_block_comment

            break
          end
        end

        def scan_line_comment(in_macro_body)
          if in_macro_body
            scan(Patterns::PP_LINE_COMMENT)
          else
            scan(Patterns::LINE_COMMENT)
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

        def scan_next_token(in_macro_body)
          token =
            scan_directive || scan_nl(in_macro_body) || scan_string || scan_number || scan_symbol || scan_word
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

          if RUBY_VERSION >= '4.0'
            Token.new(text.lstrip('`'), :PP_MACRO_ID, pos)
          else
            Token.new(text[1..], :PP_MACRO_ID, pos)
          end
        end

        def scan_nl(in_macro_body)
          return unless in_macro_body

          { PP_NL: Patterns::PP_NL, NL: Patterns::NL }.each do |kind, pattern|
            text, pos = scan(pattern)
            next unless text

            return Token.new(text, kind, pos)
          end

          nil
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
