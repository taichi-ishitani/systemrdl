# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Literal
      include Common

      def initialize(node)
        super(node.token_range)
        @node = node
        evaluate_literal
      end

      attr_reader :value

      def evaluate(_instance, **_optargs)
        @evaluated ||= Value.new(value, type, token_range)
      end

      def expression_width(_instance)
        type.width
      end

      def token_range
        @node.token_range
      end

      private

      def type
      end

      def token
        @node.children[0]
      end

      def text
        token.text
      end
    end

    class Boolean < Literal
      private

      def type
        Type.boolean
      end

      def evaluate_literal
        @value = text == 'true'
      end
    end

    class Number < Literal
      private

      def type
        Type.longint
      end

      def evaluate_literal
        @value = Integer(text)
      end
    end

    class VerilogNumber < Literal
      private

      attr_reader :type

      def evaluate_literal
        match_data, base =
          case text.tr('_', '')
          when Parser::Patterns::VERILOG_HEX_NUMBER then [Regexp.last_match, 16]
          when Parser::Patterns::VERILOG_DEC_NUMBER then [Regexp.last_match, 10]
          when Parser::Patterns::VERILOG_BIN_NUMBER then [Regexp.last_match, 2]
          end
        width = match_data.captures[0].to_i
        value = match_data.captures[1].to_i(base)

        check_bit_width(value, width)

        @type = Type.bit(width)
        @value = value
      end

      def check_bit_width(value, width)
        return if value.bit_length <= width

        message = "value of number does not fit within the specified bit width: #{text}"
        raise_evaluation_error(message, token_range)
      end
    end

    class String < Literal
      private

      def type
        Type.string
      end

      def evaluate_literal
        @value = text[1..-2]
      end
    end

    class EnumLiteral < Literal
      private

      def evaluate_literal
        @value = text.to_sym
      end
    end

    class AccessType < EnumLiteral
      private

      def type
        Type.builtin_enum(:accesstype)
      end

      def evaluate_literal
        @value =
          if ['rw', 'wr'].include?(text)
            :rw
          else
            super
          end
      end
    end

    class OnReadType < EnumLiteral
      private

      def type
        Type.builtin_enum(:onreadtype)
      end
    end

    class OnWriteType < EnumLiteral
      private

      def type
        Type.builtin_enum(:onwritetype)
      end
    end

    class AddressingType < EnumLiteral
      private

      def type
        Type.builtin_enum(:addressingtype)
      end
    end

    class PrecedenceType < EnumLiteral
      private

      def type
        Type.builtin_enum(:precedencetype)
      end
    end
  end
end
