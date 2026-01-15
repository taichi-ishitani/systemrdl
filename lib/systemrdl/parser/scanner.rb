# frozen_string_literal: true

module SystemRDL
  module Parser
    KEYWORDS = {
      BOOLEAN: /(?:true|false)\b/
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

        line = @line
        column = @column
        update_state(text)

        [text, line, column]
      end

      def scan_token(kind, pattern)
        text, line, column = scan(pattern)
        text && create_token(kind, text, line, column)
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

        token = scan_keyword
        return token if token

        raise
      end

      def scan_keyword
        KEYWORDS.each do |kind, pattern|
          token = scan_token(kind, pattern)
          return token if token
        end

        nil
      end
    end
  end
end
