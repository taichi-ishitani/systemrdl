# frozen_string_literal: true

module SystemRDL
  module HelerMethods
    def data_type(type)
      builtin_types = [
        :bit, :longint, :boolean, :string, :accesstype,
        :addressingtype, :onreadtype, :onwritetype
      ]
      if builtin_types.include?(type)
        be_instance_of(AST::DataType).and __send__("be_#{type}")
      else
        be_instance_of(AST::DataType).and be_user_defined.and have_attributes(data_type: identifer(type))
      end
    end

    def true_literal
      be_instance_of(AST::TrueLiteral)
    end

    def false_literal
      be_instance_of(AST::FalseLiteral)
    end

    def number_literal(number, width: nil)
      be_instance_of(AST::NumberLiteral).and have_attributes(number: number, width: width)
    end

    def string_literal(string)
      be_instance_of(AST::StringLiteral).and have_attributes(string: string)
    end

    def accesstype_literal(type)
      be_instance_of(AST::AccesstypeLiteral).and have_attributes(accesstype: type)
    end

    def onreadtype_literal(type)
      be_instance_of(AST::OnreadtypeLiteral).and have_attributes(onreadtype: type)
    end

    def onwritetype_literal(type)
      be_instance_of(AST::OnwritetypeLiteral).and have_attributes(onwritetype: type)
    end

    def addressingtype_literal(type)
      be_instance_of(AST::AddressingtypeLiteral).and have_attributes(addressingtype: type)
    end

    def precedencetype_literal(type)
      be_instance_of(AST::PrecedencetypeLiteral).and have_attributes(precedencetype: type)
    end

    def identifer(id)
      be_instance_of(AST::ID).and have_attributes(id: id.to_sym)
    end
  end
end
