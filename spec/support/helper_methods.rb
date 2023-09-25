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

    def accesstype_literal(type)
      proc do |result|
        result.is_a?(AST::AccesstypeLiteral) && result.accesstype == type
      end
    end

    def onreadtype_literal(type)
      proc do |result|
        result.is_a?(AST::OnreadtypeLiteral) && result.onreadtype == type
      end
    end

    def onwritetype_literal(type)
      proc do |result|
        result.is_a?(AST::OnwritetypeLiteral) && result.onwritetype == type
      end
    end

    def addressingtype_literal(type)
      proc do |result|
        result.is_a?(AST::AddressingtypeLiteral) && result.addressingtype == type
      end
    end

    def precedencetype_literal(type)
      proc do |result|
        result.is_a?(AST::PrecedencetypeLiteral) && result.precedencetype == type
      end
    end
  end
end
