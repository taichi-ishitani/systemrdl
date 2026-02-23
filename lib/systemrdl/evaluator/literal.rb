# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Literal
      include RaiseEvaluationError

      def initialize(node)
        @node = node
        evaluate_literal
      end

      attr_reader :value

      def evaluate(**_optargs)
      end

      def expression_width
      end

      def position
        @node.range.head
      end

      private

      def token
        @node.children[0]
      end

      def text
        token.text
      end
    end

    class Boolean < Literal
      def type
        :boolean
      end

      def expression_width
        1
      end

      private

      def evaluate_literal
        @value = text == 'true'
      end
    end

    class Number < Literal
      def type
        :bit
      end

      def width
        64
      end

      def expression_width
        width
      end

      private

      def evaluate_literal
        @value = Integer(text)
      end
    end

    class VerilogNumber < Literal
      attr_reader :width

      def type
        :bit
      end

      def expression_width
        width
      end

      private

      def evaluate_literal
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

      def check_bit_width(value, width)
        return if value.bit_length <= width

        message = "value of number does not fit within the specified bit width: #{text}"
        raise_evaluation_error(message, token.position)
      end
    end

    class String < Literal
      def type
        :string
      end

      private

      def evaluate_literal
        @value = text[1..-2]
      end
    end

    class AccessType < Literal
      def type
        :access_type
      end

      private

      def evaluate_literal
        @value =
          if ['rw', 'wr'].include?(text)
            :rw
          else
            text.to_sym
          end
      end
    end

    class OnReadType < Literal
      def type
        :on_read_type
      end

      private

      def evaluate_literal
        @value = text.to_sym
      end
    end

    class OnWriteType < Literal
      def type
        :on_write_type
      end

      private

      def evaluate_literal
        @value = text.to_sym
      end
    end

    class AddressingType < Literal
      def type
        :addressing_type
      end

      private

      def evaluate_literal
        @value = text.to_sym
      end
    end
  end
end
