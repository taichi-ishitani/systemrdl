# frozen_string_literal: true

module SystemRDL
  module AST
    class Position
      def initialize(filename, line, column)
        @filename = filename
        @line = line
        @column = column
        freeze
      end

      attr_reader :filename
      attr_reader :line
      attr_reader :column

      def to_s
        "filename: #{filename} line: #{line} column: #{column}"
      end
    end

    class Token
      def initialize(text, kind, position)
        @text = text
        @kind = kind
        @position = position
        freeze
      end

      attr_reader :text
      attr_reader :kind
      attr_reader :position

      def ==(other)
        text == ((other.is_a?(Token) && other.text) || text)
      end
    end

    class TokenRange
      def initialize(head, tail = nil)
        @head = head
        @tail = tail || head
        freeze
      end

      attr_reader :head
      attr_reader :tail
    end
  end
end
