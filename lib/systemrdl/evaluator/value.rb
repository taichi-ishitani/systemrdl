# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Value
      include RaiseEvaluationError

      def initialize(node)
        @node = node
      end

      attr_reader :value

      private

      def token
        @node.children[0]
      end

      def text
        token.text
      end
    end

    class Boolean < Value
      def type
        :boolean
      end

      def evaluate
        @value = text == 'true'
      end
    end

    class Number < Value
      def type
        :longint
      end

      def width
        64
      end

      def evaluate
        @value = Integer(text)
      end
    end

    class VerilogNumber < Value
      attr_reader :width

      def type
        :bit
      end

      def evaluate
        match_data, base =
          case text.tr('_', '')
          when Parser::Scanner::VERILOG_HEX_NUMBER then [Regexp.last_match, 16]
          when Parser::Scanner::VERILOG_DEC_NUMBER then [Regexp.last_match, 10]
          when Parser::Scanner::VERILOG_BIN_NUMBER then [Regexp.last_match, 2]
          end
        @width = match_data.captures[0].to_i
        @value = match_data.captures[1].to_i(base)

        check_bit_width(@value, @width)
      end

      private

      def check_bit_width(value, width)
        return if value.bit_length <= width

        message = "value of number does not fit within the specified bit width: #{text}"
        raise_evaluation_error(message, token.position)
      end
    end

    class String < Value
      def type
        :string
      end

      def evaluate
        @value = text[1..-2]
      end
    end

    class AccessType < Value
      def type
        :access_type
      end

      def evaluate
        @value =
          if ['rw', 'wr'].include?(text)
            :rw
          else
            text.to_sym
          end
      end
    end

    class OnReadType < Value
      def type
        :on_read_type
      end

      def evaluate
        @value = text.to_sym
      end
    end

    class OnWriteType < Value
      def type
        :on_write_type
      end

      def evaluate
        @value = text.to_sym
      end
    end

    class AddressingType < Value
      def type
        :addressing_type
      end

      def evaluate
        @value = text.to_sym
      end
    end
  end
end
