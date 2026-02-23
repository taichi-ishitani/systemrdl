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

        if operand.type != :boolean
          [operand.value, width || operand.width]
        elsif operand.value
          [1, 1]
        else
          [0, 1]
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
          when :~ then negation
          when :+ then plus(width)
          when :- then minus(width)
          when :& then reduction(:&, 1, false)
          when :| then reduction(:|, 0, false)
          when :^ then reduction(:^, 0, false)
          when :'~&' then reduction(:&, 1, true)
          when :'~|' then reduction(:|, 0, true)
          else reduction(:^, 0, true)
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

      def negation
        value, width = to_int(@operand)
        [mask(~value, width), :bit, width]
      end

      def plus(width)
        width ||= @operand.expression_width
        value, width = to_int(@operand, width)
        [value, :bit, width]
      end

      def minus(width)
        width ||= @operand.expression_width
        value, width = to_int(@operand, width)
        [mask(-value, width), :bit, width]
      end

      def reduction(operator, initial_value, negate)
        value, width = to_int(@operand)
        result = width.times.inject(initial_value) do |r, i|
          r.__send__(operator, value[i])
        end

        if negate
          [mask(~result, 1), :bit, 1]
        else
          [result, :bit, 1]
        end
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
          when :'&&', :'||' then logical_op(@operator)
          when :==, :!=, :<, :>, :<=, :>= then logical_equality_relational_op(@operator)
          when :&, :|, :^ then bit_op(@operator, width, false)
          when :'~^', :'^~' then bit_op(:^, width, true)
          when :<<, :>>, :** then shift_power_op(@operator, width)
          else arithmetic_op(@operator, width)
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

      def logical_op(operator)
        lhs = to_boolean(@l_operand)
        rhs = to_boolean(@r_operand)
        if operator == :'&&'
          [lhs && rhs, :boolean]
        else
          [lhs || rhs, :boolean]
        end
      end

      def logical_equality_relational_op(operator)
        lhs, rhs =
          if [@l_operand, @r_operand].all? { integral_operand?(_1) }
            width = eval_expression_width
            lhs, _ = to_int(@l_operand, width)
            rhs, _ = to_int(@r_operand, width)
            [lhs, rhs]
          elsif @l_operand.type == @r_operand.type
            @l_operand.evaluate
            @r_operand.evaluate
            [@l_operand.value, @r_operand.value]
          else
            # todo
            # report error
          end

        [lhs.__send__(operator, rhs), :boolean]
      end

      def bit_op(operator, width, negation)
        width ||= eval_expression_width

        lhs, _ = to_int(@l_operand, width)
        rhs, _ = to_int(@r_operand, width)

        result = lhs.__send__(operator, rhs)
        result = ~result if negation
        [mask(result, width), :bit, width]
      end

      def shift_power_op(operator, width)
        width ||= eval_expression_width

        lhs, _ = to_int(@l_operand, width)
        rhs, _ = to_int(@r_operand)

        result = lhs.__send__(operator, rhs)
        [mask(result, width), :bit, width]
      end

      def arithmetic_op(operator, width)
        width ||= eval_expression_width

        lhs, _ = to_int(@l_operand, width)
        rhs, _ = to_int(@r_operand, width)

        result = lhs.__send__(operator, rhs)
        [mask(result, width), :bit, width]
      end
    end
  end
end
