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

    def boolean(value)
      value && true_literal || false_literal
    end

    def number_literal(number, width: nil)
      be_instance_of(AST::NumberLiteral).and have_attributes(number: number, width: width)
    end

    alias_method :number, :number_literal

    def string_literal(string)
      be_instance_of(AST::StringLiteral).and have_attributes(string: string)
    end

    alias_method :string, :string_literal

    def accesstype_literal(type)
      be_instance_of(AST::AccesstypeLiteral).and have_attributes(accesstype: type)
    end

    alias_method :accesstype, :accesstype_literal

    def onreadtype_literal(type)
      be_instance_of(AST::OnreadtypeLiteral).and have_attributes(onreadtype: type)
    end

    alias_method :onreadtype, :onreadtype_literal

    def onwritetype_literal(type)
      be_instance_of(AST::OnwritetypeLiteral).and have_attributes(onwritetype: type)
    end

    alias_method :onwritetype, :onwritetype_literal

    def addressingtype_literal(type)
      be_instance_of(AST::AddressingtypeLiteral).and have_attributes(addressingtype: type)
    end

    alias_method :addressingtype, :addressingtype_literal

    def precedencetype_literal(type)
      be_instance_of(AST::PrecedencetypeLiteral).and have_attributes(precedencetype: type)
    end

    alias_method :precedencetype, :precedencetype_literal

    def identifer(id)
      be_instance_of(AST::ID).and have_attributes(id: id.to_sym)
    end

    alias_method :id, :identifer

    def this_keyword
      be_instance_of(AST::ThisKeyword)
    end

    def reference_element(id)
      id_matcher = id.is_a?(String) && identifer(id) || id
      be_instance_of(AST::ReferenceElement).and have_attributes(id: id_matcher)
    end

    def reference(*elements, property: nil)
      instance_refernce_matcher =
        match(elements.map { |e| reference_element(e) })
      property_matcher =
        case property
        when NilClass then be_nil
        when String then identifer(property)
        else property
        end
      be_instance_of(AST::Reference)
        .and have_attributes(instance_refernce: instance_refernce_matcher, property: property_matcher)
    end

    def cast_operation(casting_type, expression)
      be_instance_of(AST::CastOperation)
        .and have_attributes(casting_type: casting_type, expression: expression)
    end

    alias_method :cast, :cast_operation

    def unary_operation(operator, operand)
      be_instance_of(AST::UnaryOperation)
        .and have_attributes(operator: operator, operand: operand)
    end

    alias_method :u_op, :unary_operation

    def binary_operation(operator, l_operand, r_operand)
      be_instance_of(AST::BinaryOperation)
        .and have_attributes(operator: operator, l_operand: l_operand, r_operand: r_operand)
    end

    alias_method :b_op, :binary_operation

    def conditional_operation(condition, true_operand, false_operand)
      be_instance_of(AST::ConditionalOperation)
        .and have_attributes(condition: condition, true_operand: true_operand, false_operand: false_operand)
    end

    alias_method :c_op, :conditional_operation
  end
end
