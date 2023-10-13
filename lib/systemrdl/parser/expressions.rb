# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:constant_primary) do
        [
          number_literal, string_literal, boolean_literal, accesstype_literal,
          onreadtype_literal, onwritetype_literal, addressingtype_literal, this_keyword,
          property_ref, instance_ref, bracketed(constant_expression)
        ].inject(:|) >> spaces?
      end

      rule(:cast_operation) do
        casting_type = (simple_type | constant_primary) >> spaced('\'').ignore
        expression = bracketed(constant_expression)
        (
          casting_type.repeat(1).as(:casting_type) >> expression.as(:expression)
        ) | constant_primary
      end

      rule(:unary_operation) do
        (
          unary_operator.as(:unary_operator) >> cast_operation.as(:operand) >> spaces?
        ) | cast_operation
      end

      rule(:binary_operation) do
        infix_expression(unary_operation, *binary_operator) >> spaces? |
          unary_operation
      end

      rule(:condition_operation) do
        (
          binary_operation.as(:condition) >> spaced('?').as(:operator) >>
            constant_expression.as(:true_operand) >> spaced(':') >>
            constant_expression.as(:false_operand) >> spaces?
        ) | binary_operation
      end

      rule(:constant_expression) do
        condition_operation
      end

      private

      def unary_operator
        ['!', '+', '-', '~', '&', '~&', '|', '~|', '^', '~^', '^~']
          .sort_by(&:length).reverse.map { |op| spaced(op) }.inject(:|)
      end

      def binary_operator
        operators = {
          '**': 11,
          '*': 10, '/': 10, '%': 10,
          '+': 9, '-': 9, '<<': 8, '>>': 8,
          '<': 7, '<=': 7, '>': 7, '>=': 7,
          '==': 6, '!=': 6, '&': 5,
          '^': 4, '~^': 4, '^~': 4,
          '|': 3, '&&': 2, '||': 1
        }
        operators
          .sort_by { |op, _| op.length }.reverse
          .map { |op, priority| [spaced(op), priority, :left] }
      end
    end

    define_transformer do
      rule(casting_type: sequence(:t), expression: simple(:e)) do
        t.reverse.inject(e) do |expression, type|
          AST::CastOperation.new(type, expression)
        end
      end

      rule(unary_operator: simple(:operator), operand: simple(:operand)) do
        AST::UnaryOperation.new(operator, operand)
      end

      rule(l: simple(:l), o: simple(:o), r: simple(:r)) do
        AST::BinaryOperation.new(o, l, r)
      end

      rule(
        condition: simple(:c), operator: simple(:o),
        true_operand: simple(:t), false_operand: simple(:f)
      ) do
        AST::ConditionalOperation.new(o, c, t, f)
      end
    end
  end
end
