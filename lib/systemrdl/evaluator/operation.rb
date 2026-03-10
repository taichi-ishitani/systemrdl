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

      def to_boolean(instance, operand)
        operand.evaluate(instance)
        check_integral_operand(operand)

        if operand.type == :boolean
          operand.value
        else
          operand.value != 0
        end
      end

      def to_int(instance, operand, width = nil, evaluation: true)
        if evaluation
          operand.evaluate(instance, width:)
          check_integral_operand(operand)
        end

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

      def set_parent(node)
        @parent = node
        @operand.set_parent(node)
      end

      def evaluate(instance, width: nil)
        @value, @type, @width =
          case @operator
          when :! then logical_negation(instance)
          when :+, :-, :~ then general_op(instance, width)
          when :&, :|, :^ then reduction(instance, @operator, false)
          when :'~&' then reduction(instance, :&, true)
          when :'~|' then reduction(instance, :|, true)
          when :'~^', :'^~' then reduction(instance, :^, true)
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

      def logical_negation(instance)
        value = to_boolean(instance, @operand)
        [!value, :boolean]
      end

      def reduction(instance, operator, negate)
        value, width = to_int(instance, @operand)

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

      def general_op(instance, width)
        width ||= @operand.expression_width
        value, _ = to_int(instance, @operand, width)

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

      def set_parent(node)
        @parent = node
        @l_operand.set_parent(node)
        @r_operand.set_parent(node)
      end

      def evaluate(instance, width: nil)
        @value, @type, @width =
          case @operator
          when :'&&', :'||' then logical_op(instance)
          when :==, :!= then equality_op(instance)
          when :<, :>, :<=, :>= then relational_op(instance)
          when :<<, :>>, :** then shift_power_op(instance, width)
          when :'~^', :'^~' then general_op(instance, :^, width, true)
          else general_op(instance, @operator, width, false)
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

      def logical_op(instance)
        lhs = to_boolean(instance, @l_operand)
        rhs = to_boolean(instance, @r_operand)
        if @operator == :'&&'
          [lhs && rhs, :boolean]
        else
          [lhs || rhs, :boolean]
        end
      end

      def equality_op(instance)
        lhs, rhs = eval_eq_operands(instance)
        [lhs.__send__(@operator, rhs), :boolean]
      end

      def eval_eq_operands(instance)
        width = eval_expression_width
        @l_operand.evaluate(instance, width:)
        @r_operand.evaluate(instance, width:)

        if [@l_operand, @r_operand].all? { integral_operand?(_1) }
          lhs, _ = to_int(instance, @l_operand, evaluation: false)
          rhs, _ = to_int(instance, @r_operand, evaluation: false)
          [lhs, rhs]
        elsif @l_operand.type == @r_operand.type
          [@l_operand.value, @r_operand.value]
        else
          message = "#{@r_operand.type} type is not compatible with #{@l_operand.type} type"
          raise_evaluation_error message, @r_operand.position
        end
      end

      def relational_op(instance)
        lhs, rhs, _ = integral_operands(instance, nil)
        [lhs.__send__(@operator, rhs), :boolean]
      end

      def shift_power_op(instance, width)
        width ||= eval_expression_width
        lhs, _ = to_int(instance, @l_operand, width)
        rhs, _ = to_int(instance, @r_operand)

        result = lhs.__send__(@operator, rhs)
        [mask(result, width), :bit, width]
      end

      def general_op(instance, operator, width, negate)
        lhs, rhs, width = integral_operands(instance, width)

        if div_by_0?(rhs)
          message = 'divisor should be non zero value'
          raise_evaluation_error message, @r_operand.position
        end

        result = lhs.__send__(operator, rhs)
        result = ~result if negate
        [mask(result, width), :bit, width]
      end

      def div_by_0?(rhs)
        [:/, :%].include?(@operator) && rhs == 0
      end

      def integral_operands(instance, width)
        width ||= eval_expression_width
        lhs, _ = to_int(instance, @l_operand, width)
        rhs, _ = to_int(instance, @r_operand, width)
        [lhs, rhs, width]
      end
    end
  end
end
