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

      def test?
        @test
      end
    end
  end
end
