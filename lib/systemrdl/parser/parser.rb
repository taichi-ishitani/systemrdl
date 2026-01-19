# frozen_string_literal: true

module SystemRDL
  module Parser
    class Parser < GeneratedParser
      include RaiseParseError

      def initialize(scanner, debug: false, test: false)
        @scanner = scanner
        @yydebug = debug
        @test = test
        super()
      end

      def parse
        do_parse
      end

      private

      def next_token
        @scanner.next_token
      end

      def on_error(_token_id, value, _value_stack)
        message = "syntax error on value '#{value.text}' (#{value.kind})"
        raise_parse_error message, value.position
      end

      def to_list(values, include_separator:)
        if include_separator
          [values[0], *values[1]&.map { |_, value| value }]
        else
          [values[0], *values[1]]
        end
      end

      def to_token_range(*values)
        head = values.first
        tail = values.last
        if values.size == 1 && head.is_a?(AST::Base)
          head.range
        else
          head_token = (head.is_a?(AST::Base) && head.range.head) || head
          tail_token = (head.is_a?(AST::Base) && head.range.tail) || tail
          AST::TokenRange.new(head_token, tail_token)
        end
      end

      def test?
        @test
      end
    end
  end
end
