# frozen_string_literal: true

module SystemRDL
  module HelerMethods
    def true_literal
      proc { |result| result.is_a?(AST::TrueLiteral) }
    end

    def false_literal
      proc { |result| result.is_a?(AST::FalseLiteral) }
    end

    def number_literal(number, width: nil)
      proc do |result|
        result.is_a?(AST::NumberLiteral) && result.number && result.width == width
      end
    end

    def string_literal(string)
      proc do |result|
        result.is_a?(AST::StringLiteral) && result.string == string
      end
    end
  end
end
