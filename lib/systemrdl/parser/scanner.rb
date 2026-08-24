# frozen_string_literal: true

module SystemRDL
  module Parser
    class Scanner
      def initialize(code, filename, test)
        source = Processor::Source.new(code, 1, 1)
        @processor = Processor::Default.new(source, filename)
        @filename = filename
        @control_tokens = []
        @control_tokens << create_test_token(test) if test
      end

      def next_token
        if @control_tokens.empty?
          @processor.skip_blank
          push_eos_tokens if @processor.eos?
        end

        token =
          if @control_tokens.empty?
            @processor.next_token
          else
            @control_tokens.shift
          end
        token && [token.kind, token]
      end

      private

      def push_eos_tokens
        @control_tokens << create_control_token(:EOS)
        @control_tokens << nil
      end

      def create_token(kind, text, line, column)
        position = Position.new(@filename, line, column)
        Token.new(text, kind, position)
      end

      def create_control_token(kind)
        Token.create(kind, '', @filename, @processor.line, @processor.column)
      end

      def create_test_token(test)
        kind = :"__test_#{test}__".upcase
        create_control_token(kind)
      end

      def scan_next_token
        token =
          scan_string || scan_number || scan_symbol || scan_word
        return token if token

        char = peek_char
        raise_parse_error "illegal character `#{char}`", current_position
      end
    end
  end
end
