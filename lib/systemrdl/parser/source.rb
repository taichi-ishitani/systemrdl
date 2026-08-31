# frozen_string_literal: true

module SystemRDL
  module Parser
    class Source
      def initialize(code, filename, line, column)
        @ss = StringScanner.new(code)
        @filename = filename
        @line = line
        @column = column
      end

      attr_reader :filename
      attr_reader :line
      attr_reader :column

      def eos?
        @ss.eos?
      end

      def scan(pattern)
        text = @ss.scan(pattern)
        return unless text

        line = @line
        column = @column
        update_state(text)

        pos = Position.new(@filename, line, column)
        [text, pos]
      end

      def peek(pattern)
        @ss.check(pattern)
      end

      def advance(text)
        @ss.pos += text.bytesize
        update_state(text)
      end

      def position
        Position.new(@filename, @line, @column)
      end

      private

      def update_state(text)
        return if text.empty?

        n_newline = text.count("\n")
        @line += n_newline

        @column =
          if /\R\z/.match?(text)
            1
          elsif n_newline > 0
            last = text.lines.last
            last.length
          else
            @column + text.length
          end
      end
    end
  end
end
