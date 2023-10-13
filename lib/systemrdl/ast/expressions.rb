# frozen_string_literal: true

module SystemRDL
  module AST
    class CastOperation < Base
      def initialize(casting_type, expression)
        assign_properties(casting_type: casting_type, expression: expression)
        super(:cast_operation, casting_type)
      end

      attr_reader :casting_type
      attr_reader :expression
    end

    class UnaryOperation < Base
      def initialize(operator, operand)
        assign_properties(operator: operator.to_sym, operand: operand)
        super(:unary_operation, operator)
      end

      attr_reader :operator
      attr_reader :operand
    end

    class BinaryOperation < Base
      def initialize(operator, l_operand, r_operand)
        assign_properties(
          operator: operator.to_sym, l_operand: l_operand, r_operand: r_operand
        )
        super(:binary_operation, operator)
      end

      attr_reader :operator
      attr_reader :l_operand
      attr_reader :r_operand
    end

    class ConditionalOperation < Base
      def initialize(operator, condition, true_operand, false_operand)
        assign_properties(
          condition: condition,
          true_operand: true_operand, false_operand: false_operand
        )
        super(:conditional_operation, operator)
      end

      attr_reader :condition
      attr_reader :true_operand
      attr_reader :false_operand
    end
  end
end
