# frozen_string_literal: true

module SystemRDL
  module Evaluator
    class Operation
      include Common

      attr_reader :token_range

      def evaluate(instance, width: nil, **_optargs)
        value, type = eval_operation(instance, width)
        Value.new(value, type, token_range)
      end

      private

      def integral_operand?(operand)
        operand.type.kind in :bit | :boolean | :enum
      end

      def eval_operand(instance, operand, width, check:)
        result = operand.evaluate(instance, width:)
        if check && !integral_operand?(result)
          message = "non integral operand is given: #{result.type}"
          raise_evaluation_error message, token_range
        end

        result
      end

      def to_boolean(instance, operand)
        operand = eval_operand(instance, operand, nil, check: true)
        operand.cast(Type.boolean)
      end

      def to_int(instance, operand, width = nil, evaluation: true)
        operand = eval_operand(instance, operand, width, check: true) if evaluation
        operand.cast(Type.bit(width))
      end

      def mask(value, width)
        value & ((1 << width) - 1)
      end
    end

    class UnaryOperation < Operation
      def initialize(operator, operand, token_range)
        @operator = operator
        @operand = operand
        super(token_range)
      end

      def connect(parent, component)
        super
        @operand.connect(self, component)
      end

      def expression_width(instance)
        if [:~, :+, :-].include?(@operator)
          @operand.expression_width(instance)
        else
          1
        end
      end

      private

      def eval_operation(instance, width)
        case @operator
        when :! then logical_negation(instance)
        when :+, :-, :~ then general_op(instance, width)
        when :&, :|, :^ then reduction(instance, @operator, false)
        when :'~&' then reduction(instance, :&, true)
        when :'~|' then reduction(instance, :|, true)
        when :'~^', :'^~' then reduction(instance, :^, true)
        end
      end

      def logical_negation(instance)
        value = to_boolean(instance, @operand)
        [!value.value, value.type]
      end

      def reduction(instance, operator, negate)
        value = to_int(instance, @operand)

        init_value = { '&': 1, '|': 0, '^': 0 }[operator]
        result = value.type.width.times.inject(init_value) do |r, i|
          r.__send__(operator, value.value[i])
        end

        if negate
          [mask(~result, 1), Type.bit(1)]
        else
          [result, Type.bit(1)]
        end
      end

      def general_op(instance, width)
        width ||= @operand.expression_width(instance)
        value = to_int(instance, @operand, width)

        op = { '+': :+@, '-': :-@, '~': :~ }[@operator]
        result = value.value.__send__(op)
        [mask(result, width), value.type]
      end
    end

    class BinaryOperation < Operation
      def initialize(operator, l_operand, r_operand, token_range)
        @operator = operator
        @l_operand = l_operand
        @r_operand = r_operand
        super(token_range)
      end

      def connect(parent, component)
        super
        @l_operand.connect(self, component)
        @r_operand.connect(self, component)
      end

      def expression_width(instance)
        if [:'&&', :'||', :==, :!=, :<, :>, :<=, :>=].include?(@operator)
          1
        else
          eval_expression_width(instance)
        end
      end

      private

      def eval_expression_width(instance)
        lhs_width = @l_operand.expression_width(instance)
        return lhs_width if [:<<, :>>, :**].include?(@operator)

        rhs_width = @r_operand.expression_width(instance)

        if lhs_width && rhs_width
          [lhs_width, rhs_width].max
        else
          lhs_width || rhs_width
        end
      end

      def eval_operation(instance, width)
        case @operator
        when :'&&', :'||' then logical_op(instance)
        when :==, :!= then equality_op(instance)
        when :<, :>, :<=, :>= then relational_op(instance)
        when :<<, :>>, :** then shift_power_op(instance, width)
        when :'~^', :'^~' then general_op(instance, :^, width, true)
        else general_op(instance, @operator, width, false)
        end
      end

      def logical_op(instance)
        lhs = to_boolean(instance, @l_operand).value
        rhs = to_boolean(instance, @r_operand).value
        if @operator == :'&&'
          [lhs && rhs, Type.boolean]
        else
          [lhs || rhs, Type.boolean]
        end
      end

      def equality_op(instance)
        lhs, rhs = eval_eq_operands(instance)
        [lhs.__send__(@operator, rhs), Type.boolean]
      end

      def eval_eq_operands(instance)
        width = eval_expression_width(instance)
        l_operand = eval_operand(instance, @l_operand, width, check: false)
        r_operand = eval_operand(instance, @r_operand, width, check: false)

        if [l_operand, r_operand].all? { integral_operand?(_1) }
          lhs = to_int(instance, l_operand, evaluation: false).value
          rhs = to_int(instance, r_operand, evaluation: false).value
          [lhs, rhs]
        elsif l_operand.type.kind == r_operand.type.kind
          [l_operand.value, r_operand.value]
        else
          message = "#{r_operand.type} type is not compatible with #{l_operand.type} type"
          raise_evaluation_error message, @r_operand.token_range
        end
      end

      def relational_op(instance)
        lhs, rhs = integral_operands(instance, nil)
        [lhs.value.__send__(@operator, rhs.value), Type.boolean]
      end

      def shift_power_op(instance, width)
        width ||= eval_expression_width(instance)
        lhs = to_int(instance, @l_operand, width)
        rhs = to_int(instance, @r_operand)

        result = lhs.value.__send__(@operator, rhs.value)
        [mask(result, width), lhs.type]
      end

      def general_op(instance, operator, width, negate)
        lhs, rhs = integral_operands(instance, width)

        if div_by_0?(rhs)
          message = 'divisor should be non zero value'
          raise_evaluation_error message, @r_operand.token_range
        end

        result = lhs.value.__send__(operator, rhs.value)
        result = ~result if negate
        [mask(result, lhs.type.width), lhs.type]
      end

      def div_by_0?(rhs)
        [:/, :%].include?(@operator) && rhs.value == 0
      end

      def integral_operands(instance, width)
        width ||= eval_expression_width(instance)
        lhs = to_int(instance, @l_operand, width)
        rhs = to_int(instance, @r_operand, width)
        [lhs, rhs]
      end
    end
  end
end
