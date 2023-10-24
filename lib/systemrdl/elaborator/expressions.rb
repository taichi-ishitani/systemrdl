# frozen_string_literal: true

module SystemRDL
  class Elaborator
    private

    def on_cast_operation(node, context)
      casting_type = process(node.casting_type, context)
      expression = process(node.expression, context)

      check_integral_type(expression.data_type, expression.position)
      if casting_type.is_a?(AST::DataType)
        type_based_cast(casting_type.data_type, expression, casting_type.position)
      else
        width_based_cast(casting_type, expression)
      end
    end

    def type_based_cast(data_type, expression, position)
      case [data_type, expression.data_type]
      in [:boolean, _]
        Element::BooleanValue.new(expression.to_boolean, position)
      in [:longint, _]
        Element::NumberValue.new(expression.to_i, 64, position)
      in [_, :boolean]
        Element::NumberValue.new(expression.to_i, 1, position)
      else
        expression
      end
    end

    def width_based_cast(width, expression)
      check_integral_type(width.data_type, width.position) do |data_type|
        "the specified bit width should be an integral value: #{data_type}"
      end
      width.to_boolean ||
        (error 'the specified bit width should not be 0', width.position)

      Element::NumberValue.new(expression.to_i, width.to_i, width.position)
    end

    def on_unary_operation(node, context)
      operand = process(node.operand, context)

      check_integral_type(operand.data_type, operand.position) do |data_type|
        "the given operand should be an integral value: #{data_type}"
      end
      case node.operator
      when :!
        unary_logical_operation(operand, node.position)
      when :~
        unary_negation_operation(operand, node.position)
      when :+, :-
        unary_arithmetic_operation(node.operator, operand, node.position)
      else
        unary_reduction_operation(node.operator, operand, node.position)
      end
    end

    def unary_logical_operation(operand, position)
      Element::BooleanValue.new(!operand.to_boolean, position)
    end

    def unary_negation_operation(operand, position)
      value = to_number(operand)
      Element::NumberValue.new(~value, value.width, position)
    end

    def unary_arithmetic_operation(operator, operand, position)
      value = to_number(operand)
      if operator == :-
        Element::NumberValue.new(-value, value.width, position)
      else
        value
      end
    end

    def unary_reduction_operation(operator, operand, position)
      result =
        case operator
        when :&, :'~&' then do_reduction_operation(:&, operand, 1)
        when :|, :'~|' then do_reduction_operation(:|, operand, 0)
        else do_reduction_operation(:^, operand, 0)
        end
      if [:&, :|, :^].include?(operator)
        Element::NumberValue.new(result, 1, position)
      else
        Element::NumberValue.new(~result, 1, position)
      end
    end

    def do_reduction_operation(operator, operand, initial_value)
      value = to_number(operand)
      Array
        .new(value.width) { |i| value[i] }
        .inject(initial_value, operator)
    end

    def on_binary_operation(node, context)
      operands =
        [node.l_operand, node.r_operand].map { |o| process(o, context) }

      unless [:'==', :'!='].include?(node.operator)
        operands.each do |o|
          check_integral_type(o.data_type, o.position) do |data_type|
            "the given operand should be an integral value: #{data_type}"
          end
        end
      end
      do_binary_operation(node.operator, operands, node.position)
    end

    def do_binary_operation(operator, operands, position)
      case operator
      when :'&&', :'||'
        binary_logical_operation(operator, operands, position)
      when :<, :>, :'<=', :'>='
        binary_relational_operation(operator, operands, position)
      when :'==', :'!='
        binary_equality_operation(operator, operands, position)
      when :<<, :>>
        binary_shift_operation(operator, operands, position)
      when :&, :|, :^, :'~^', :'^~'
        binary_bitwise_operation(operator, operands, position)
      else
        binary_arithmetic_operation(operator, operands, position)
      end
    end

    def binary_logical_operation(operator, operands, position)
      op_l, op_r = operands.map(&:to_boolean)
      if operator == :'&&'
        Element::BooleanValue.new(op_l && op_r, position)
      else
        Element::BooleanValue.new(op_l || op_r, position)
      end
    end

    def binary_relational_operation(operator, operands, position)
      op_l, op_r = operands.map(&method(:to_number))
      result = op_l.__send__(operator, op_r)
      Element::BooleanValue.new(result, position)
    end

    def binary_equality_operation(operator, operands, position)
      op_l, op_r =
        if operands.all? { |o| integral_type?(o.data_type) }
          operands.map(&method(:to_number))
        else
          operands.map(&:__getobj__)
        end
      result = op_l.__send__(operator, op_r)
      Element::BooleanValue.new(result, position)
    end

    def binary_shift_operation(operator, operands, position)
      op_l, op_r = operands.map(&method(:to_number))
      result = op_l.__send__(operator, op_r)
      Element::NumberValue.new(result, op_l.width, position)
    end

    def binary_bitwise_operation(operator, operands, position)
      op_l, op_r = operands.map(&method(:to_number))
      result =
        if [:'^~', :'~^'].include?(operator)
          ~(op_l ^ op_r)
        else
          op_l.__send__(operator, op_r)
        end
      width = [op_l.width, op_r.width].max
      Element::NumberValue.new(result, width, position)
    end

    def binary_arithmetic_operation(operator, operands, position)
      op_l, op_r = operands.map(&method(:to_number))
      result = op_l.__send__(operator, op_r)
      width =
        if operator == :**
          op_l.width
        else
          [op_l.width, op_r.width].max
        end
      Element::NumberValue.new(result, width, position)
    rescue ZeroDivisionError
      message = "the second operand for the #{operator} operation should not 0"
      error message, op_r.position
    end

    def integral_type?(data_type)
      [:boolean, :number].include?(data_type)
    end

    def check_integral_type(data_type, position)
      return if integral_type?(data_type)

      message =
        if block_given?
          yield(data_type)
        else
          'the given expression should be an integral value: ' \
          "#{data_type}"
        end
      error message, position
    end

    def to_number(operand)
      type_based_cast(:number, operand, operand.position)
    end
  end
end
