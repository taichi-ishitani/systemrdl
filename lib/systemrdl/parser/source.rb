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
        @line, @column = Utils.calc_next_position(text, @line, @column)
      end
    end
  end
end
