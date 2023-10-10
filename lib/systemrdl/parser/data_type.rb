# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:integer_type_without_signing) do
        (kw_bit | kw_longint).as(:primary_data_type)
      end

      rule(:integer_type_with_signing) do
        (kw_bit >> spaces >> kw_unsigned).as(:bit_type) |
          (kw_longint >> spaces >> kw_unsigned).as(:longint_type)
      end

      rule(:boolean_type) do
        kw_boolean.as(:primary_data_type)
      end

      rule(:string_type) do
        kw_string.as(:primary_data_type)
      end

      rule(:accesstype_type) do
        kw_accesstype.as(:primary_data_type)
      end

      rule(:addressingtype_type) do
        kw_addressingtype.as(:primary_data_type)
      end

      rule(:onreadtype_type) do
        kw_onreadtype.as(:primary_data_type)
      end

      rule(:onwritetype_type) do
        kw_onwritetype.as(:primary_data_type)
      end

      rule(:user_defined_type) do
        id.as(:user_defined_type)
      end

      rule(:simple_type) do
        integer_type_without_signing | boolean_type
      end

      rule(:basic_data_type) do
        integer_type_with_signing | simple_type |
          string_type | user_defined_type
      end

      rule(:data_type) do
        accesstype_type | addressingtype_type |
          onreadtype_type | onwritetype_type | basic_data_type
      end
    end

    define_transformer do
      rule(primary_data_type: simple(:t)) do
        AST::DataType.new(t.position, t.to_sym)
      end

      rule(bit_type: simple(:t)) do
        AST::DataType.new(t.position, :bit)
      end

      rule(longint_type: simple(:t)) do
        AST::DataType.new(t.position, :longint)
      end

      rule(user_defined_type: simple(:t)) do
        AST::DataType.new(t.position, t)
      end
    end
  end
end
