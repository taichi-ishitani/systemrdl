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
        return true if [:bit, :longint, :boolean].include?(operand.type)

        message = "non integral operand is given: #{operand.type}"
        raise_evaluation_error message, position
      end

      def to_boolean(operand)
        if operand.type == :boolean
          operand.value
        else
          operand.value != 0
        end
      end

      def to_int(operand)
        if operand.type != :boolean
          [operand.value, operand.type, operand.width]
        elsif operand.value
          [1, :bit, 1]
        else
          [0, :bit, 1]
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
        integral_operand?(@operand)

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
        value, type, width = to_int(@operand)
        [mask(~value, width), type, width]
      end

      def plus
        to_int(@operand)
      end

      def minus
        value, type, width = to_int(@operand)
        [mask(-value, width), type, width]
      end

      def reduction(operator, initial_value, negate)
        value, _, width = to_int(@operand)
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
  end
end
