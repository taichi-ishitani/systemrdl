# frozen_string_literal: true

module SystemRDL
  class Elaborator
    private

    def on_cast_operation(node, context)
      casting_type = process(node.casting_type, context)
      expression = process(node.expression, context)

      check_integral_type(expression.data_type, expression.position)
      if casting_type.is_a?(AST::DataType)
        type_based_cast(casting_type, expression)
      else
        width_based_cast(casting_type, expression)
      end
    end

    def type_based_cast(type, expression)
      case [type.data_type, expression.data_type]
      in [:boolean, _]
        Element::BooleanValue.new(expression.to_boolean, type.position)
      in [:longint, _]
        Element::NumberValue.new(expression.to_i, 64, type.position)
      in [_, :boolean]
        Element::NumberValue.new(expression.to_i, 1, type.position)
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
  end
end
