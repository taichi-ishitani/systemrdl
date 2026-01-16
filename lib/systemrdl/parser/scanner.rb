# frozen_string_literal: true

module SystemRDL
  module Parser
    KEYWORDS = {
      'true' => :BOOLEAN,
      'false' => :BOOLEAN
    }.freeze

    NUMBERS = {
      /\A\d[\d_]*\z/ => :NUMBER,
      /\A0x\h[\h_]*\z/i => :NUMBER,
      /\A\d+'b[01][01_]*\z/i => :VERILOG_NUMBER,
      /\A\d+'d\d[\d_]*\z/i => :VERILOG_NUMBER,
      /\A\d+'h\h[\h_]*\z/i => :VERILOG_NUMBER
    }.freeze

    class Scanner
      def initialize(code, filename)
        @ss = StringScanner.new(code)
        @filename = filename
        @line = 1
        @column = 1
      end

      def next_token
        token = scan_next_token
        token && [token.kind, token]
      end

      private

      def eos?
        @ss.eos?
      end

      def scan(pattern)
        text = @ss.scan(pattern)
        return unless text

        line = @line
        column = @column
        update_state(text)

        [text, line, column]
      end

      def scan_token(kind, pattern)
        text, line, column = scan(pattern)
        text && create_token(kind, text, line, column)
      end

      def peek(pattern)
        @ss.check(pattern)
      end

      def peek_char
        peek(/./m)
      end

      def advance(text)
        @ss.pos += text.bytesize
        update_state(text)
      end

      def update_state(text)
        return if text.empty?

        n_newline = text.count("\n")
        @line += n_newline

        @column =
          if text[-1] == "\n"
            1
          elsif n_newline > 0
            last = text.lines.last
            last.length
          else
            @column + text.length
          end
      end

      def create_token(kind, text, line, column)
        position = AST::Position.new(@filename, line, column)
        AST::Token.new(text, kind, position)
      end

      def scan_next_token
        return if eos?

        token = scan_string
        return token if token

        token = scan_word
        return token if token

        raise
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
        create_token(:STRING, text, line, column)
      end

      def scan_word
        text, line, column = scan(/[\w']+/)
        return unless text

        KEYWORDS.each do |pattern, kind|
          next if text != pattern

          token = create_token(kind, text, line, column)
          return token
        end

        NUMBERS.each do |pattern, kind|
          next unless pattern.match?(text)

          token = create_token(kind, text, line, column)
          return token
        end

        create_token(:UNKNOWN, text, line, column)
      end
    end
  end
end
