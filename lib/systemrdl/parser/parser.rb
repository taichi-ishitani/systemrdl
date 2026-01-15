# frozen_string_literal: true

module SystemRDL
  module Parser
    class Parser < GeneratedParser
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

      def test?
        @test
      end
    end
  end
end
