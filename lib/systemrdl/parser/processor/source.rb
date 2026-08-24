# frozen_string_literal: true

module SystemRDL
  module Parser
    module Processor
      class Source
        def initialize(text, line, column)
          @ss = StringScanner.new(text)
          @line = line
          @column = column
        end

        attr_reader :line
        attr_reader :column

        def scan(pattern)
          text = @ss.scan(pattern)
          return unless text

          line = @line
          column = @column
          update_state(text)

          [text, line, column]
        end

        def peek(pattern)
          @ss.check(pattern)
        end

        def advance(text)
          @ss.pos += text.bytesize
          update_state(text)
        end

        def eos?
          @ss.eos?
        end

        private

        def update_state(text)
          return if text.empty?

          n_newline = text.count("\n")
          @line += n_newline

          @column =
            if text[-1] == "\n"
              1
            elsif n_newline > 0
              line = text.lines.last
              line.length
            else
              @column + text.length
            end
        end
      end
    end
  end
end
