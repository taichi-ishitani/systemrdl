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
        return true if [:bit, :boolean].include?(operand.type)

        message = "non integral operand is given: #{operand.type}"
        raise_evaluation_error message, position
      end

      def to_boolean(operand)
        integral_operand?(operand)
        if operand.type == :boolean
          operand.value
        else
          operand.value != 0
        end
      end

      def to_int(operand)
        integral_operand?(operand)
        if operand.type != :boolean
          [operand.value, operand.width]
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

      def evaluate
        @operand.evaluate
        @value, @type, @width =
          case @operator
          when :! then logical_negation
          when :~ then negation
          when :+ then plus
          when :- then minus
          when :& then reduction(:&, 1, false)
          when :| then reduction(:|, 0, false)
          when :^ then reduction(:^, 0, false)
          when :'~&' then reduction(:&, 1, true)
          when :'~|' then reduction(:|, 0, true)
          else reduction(:^, 0, true)
          end
      end

      def logical_negation
        value = to_boolean(@operand)
        [!value, :boolean]
      end

      def negation
        value, width = to_int(@operand)
        [mask(~value, width), :bit, width]
      end

      def plus
        value, width = to_int(@operand)
        [value, :bit, width]
      end

      def minus
        value, width = to_int(@operand)
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

      def evaluate
        @value, @type, @width =
          case @operator
          when :'&&', :'||' then logical_op(@operator)
          when :==, :!=, :<, :>, :<=, :>= then logical_equality_relational_op(@operator)
          end
      end

      private

      def logical_op(operator)
        @l_operand.evaluate
        lhs = to_boolean(@l_operand)
        @r_operand.evaluate
        rhs = to_boolean(@r_operand)

        if operator == :'&&'
          [lhs && rhs, :boolean]
        else
          [lhs || rhs, :boolean]
        end
      end

      def logical_equality_relational_op(operator)
        @l_operand.evaluate
        @r_operand.evaluate

        lhs, rhs =
          if @l_operand.type == @r_operand.type
            [@l_operand.value, @r_operand.value]
          else
            lhs, _ = to_int(@l_operand)
            rhs, _ = to_int(@r_operand)
            [lhs, rhs]
          end
        [lhs.__send__(operator, rhs), :boolean]
      end
    end
  end
end
