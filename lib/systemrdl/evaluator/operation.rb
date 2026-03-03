# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Operation
      include RaiseEvaluationError

      def initialize(range)
        @range = range
      end

      attr_reader :type
      attr_reader :width
      attr_reader :value

      def position
        @range.head
      end

      private

      def integral_operand?(operand)
        [:bit, :boolean].include?(operand.type)
      end

      def check_integral_operand(operand)
        return if integral_operand?(operand)

        message = "non integral operand is given: #{operand.type}"
        raise_evaluation_error message, position
      end

      def to_boolean(operand)
        operand.evaluate
        check_integral_operand(operand)

        if operand.type == :boolean
          operand.value
        else
          operand.value != 0
        end
      end

      def to_int(operand, width = nil)
        operand.evaluate(width:)
        check_integral_operand(operand)

        if operand.type == :boolean
          [(operand.value && 1) || 0, 1]
        else
          [operand.value, width || operand.width]
        end
      end

      def mask(value, width)
        value & ((1 << width) - 1)
      end
    end

    class UnaryOperation < Operation
      def initialize(operator, operand, range)
        @operator = operator
        @operand = operand
        super(range)
      end

      def evaluate(width: nil)
        @value, @type, @width =
          case @operator
          when :! then logical_negation
          when :+, :-, :~ then general_op(width)
          when :&, :|, :^ then reduction(@operator, false)
          when :'~&' then reduction(:&, true)
          when :'~|' then reduction(:|, true)
          when :'~^', :'^~' then reduction(:^, true)
          end
      end

      def expression_width
        if [:~, :+, :-].include?(@operator)
          @operand.expression_width
        else
          1
        end
      end

      private

      def logical_negation
        value = to_boolean(@operand)
        [!value, :boolean]
      end

      def reduction(operator, negate)
        value, width = to_int(@operand)

        init_value = { '&': 1, '|': 0, '^': 0 }[operator]
        result = width.times.inject(init_value) do |r, i|
          r.__send__(operator, value[i])
        end

        if negate
          [mask(~result, 1), :bit, 1]
        else
          [result, :bit, 1]
        end
      end

      def general_op(width)
        width ||= @operand.expression_width
        value, _ = to_int(@operand, width)

        op = { '+': :+@, '-': :-@, '~': :~ }[@operator]
        result = value.__send__(op)
        [mask(result, width), :bit, width]
      end
    end

    class BinaryOperation < Operation
      def initialize(operator, l_operand, r_operand, range)
        @operator = operator
        @l_operand = l_operand
        @r_operand = r_operand
        super(range)
      end

      def evaluate(width: nil)
        @value, @type, @width =
          case @operator
          when :'&&', :'||' then logical_op
          when :==, :!= then equality_op
          when :<, :>, :<=, :>= then relational_op
          when :<<, :>>, :** then shift_power_op(width)
          when :'~^', :'^~' then general_op(:^, width, true)
          else general_op(@operator, width, false)
          end
      end

      def expression_width
        if [:'&&', :'||', :==, :!=, :<, :>, :<=, :>=].include?(@operator)
          1
        else
          eval_expression_width
        end
      end

      private

      def eval_expression_width
        lhs_width = @l_operand.expression_width
        return lhs_width if [:<<, :>>, :**].include?(@operator)

        rhs_width = @r_operand.expression_width

        if lhs_width && rhs_width
          [lhs_width, rhs_width].max
        else
          lhs_width || rhs_width
        end
      end

      def logical_op
        lhs = to_boolean(@l_operand)
        rhs = to_boolean(@r_operand)
        if @operator == :'&&'
          [lhs && rhs, :boolean]
        else
          [lhs || rhs, :boolean]
        end
      end

      def equality_op
        lhs, rhs, _ =
          if [@l_operand, @r_operand].all? { integral_operand?(_1) }
            integral_operands(nil)
          elsif @l_operand.type == @r_operand.type
            @l_operand.evaluate
            @r_operand.evaluate
            [@l_operand.value, @r_operand.value]
          else
            # todo
            # report error
          end

        [lhs.__send__(@operator, rhs), :boolean]
      end

      def relational_op
        lhs, rhs, _ = integral_operands(nil)
        [lhs.__send__(@operator, rhs), :boolean]
      end

      def shift_power_op(width)
        width ||= eval_expression_width
        lhs, _ = to_int(@l_operand, width)
        rhs, _ = to_int(@r_operand)

        result = lhs.__send__(@operator, rhs)
        [mask(result, width), :bit, width]
      end

      def general_op(operator, width, negate)
        lhs, rhs, width = integral_operands(width)

        result = lhs.__send__(operator, rhs)
        result = ~result if negate
        [mask(result, width), :bit, width]
      end

      def integral_operands(width)
        width ||= eval_expression_width
        lhs, _ = to_int(@l_operand, width)
        rhs, _ = to_int(@r_operand, width)
        [lhs, rhs, width]
      end
    end
  end
end
