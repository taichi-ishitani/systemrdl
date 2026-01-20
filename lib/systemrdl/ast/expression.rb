# frozen_string_literal: true

module SystemRDL
  module AST
    class UnaryOperation < Base
      def initialize(range, operator, operand)
        super(:unary_operation, range, operator, operand)
      end
    end

    class BinaryOperation < Base
      def initialize(range, operator, l_operand, r_operand)
        super(:binary_operation, range, operator, l_operand, r_operand)
      end
    end
  end
end
