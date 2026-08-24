# frozen_string_literal: true

module SystemRDL
  module Parser
    Position = Data.define(:filename, :line, :column) do
      def to_s
        "filename: #{filename} line: #{line} column: #{column}"
      end
    end

    class Token
      def self.create(kind, text, filename, line, column)
        pos = Position.new(filename, line, column)
        new(text, kind, pos)
      end

      def initialize(text, kind, position)
        @text = text
        @kind = kind
        @position = position
        freeze
      end

      attr_reader :text
      attr_reader :kind
      attr_reader :position

      def to_sym
        text.to_sym
      end

      def to_token_range
        TokenRange.new(self)
      end

      def ==(other)
        text == ((other.is_a?(Token) && other.text) || other)
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
