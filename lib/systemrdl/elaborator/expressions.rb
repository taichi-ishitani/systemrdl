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

    def check_integral_type(data_type, position)
      return if [:boolean, :number].include?(data_type)

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
