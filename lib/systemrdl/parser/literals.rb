# frozen_string_literal: true

module SystemRDL
  class Parser
    #
    # Boolean literal
    #
    define_parser do
      rule(:boolean_literal) do
        (kw_true | kw_false).as(:boolean_literal) >> spaces?
      end
    end

    define_transformer do
      rule(boolean_literal: simple(:v)) do
        AST::BooleanLiteral.new(v)
      end
    end

    #
    # Number literal
    #
    define_parser do
      rule(:bin_number) do
        match('[01]') >> (str('_').maybe >> match('[01]')).repeat
      end

      rule(:dec_number) do
        match('\d') >> (str('_').maybe >> match('\d')).repeat
      end

      rule(:hex_number) do
        match('\h') >> (str('_').maybe >> match('\h')).repeat
      end

      rule(:width_value) do
        match('[1-9]') >> match('\d').repeat
      end

      rule(:verilg_binary) do
        (
          width_value.as(:width) >> (str('\'b') | str('\'B')) >> bin_number.as(:number)
        ).as(:verilg_binary)
      end

      rule(:simple_decimal) do
        dec_number.as(:simple_decimal)
      end

      rule(:verilg_decimal) do
        (
          width_value.as(:width) >> (str('\'d') | str('\'D')) >> dec_number.as(:number)
        ).as(:verilg_decimal)
      end

      rule(:simple_hexadecimal) do
        ((str('0x') | str('0X')) >> hex_number).as(:simple_hexadecimal)
      end

      rule(:verilg_hexadecimal) do
        (
          width_value.as(:width) >> (str('\'h') | str('\'H')) >> hex_number.as(:number)
        ).as(:verilg_hexadecimal)
      end

      rule(:number_literal) do
        (
          verilg_hexadecimal | verilg_decimal | verilg_binary |
          simple_hexadecimal | simple_decimal
        ) >> spaces?
      end
    end

    define_transformer do
      rule(verilg_hexadecimal: { width: simple(:w), number: simple(:n) }) do
        AST::NumberLiteral.new(n, 16, w)
      end

      rule(verilg_decimal: { width: simple(:w), number: simple(:n) }) do
        AST::NumberLiteral.new(n, 10, w)
      end

      rule(verilg_binary: { width: simple(:w), number: simple(:n) }) do
        AST::NumberLiteral.new(n, 2, w)
      end

      rule(simple_hexadecimal: simple(:n)) do
        AST::NumberLiteral.new(n, 16, nil)
      end

      rule(simple_decimal: simple(:n)) do
        AST::NumberLiteral.new(n, 10, nil)
      end
    end

    #
    # String literal
    #
    define_parser do
      rule(:string_literal) do
        (
          str('"') >> (str('\\"') | match('[^"]')).repeat >> str('"')
        ).as(:string_literal) >> spaces?
      end
    end

    define_transformer do
      rule(string_literal: simple(:s)) do
        AST::StringLiteral.new(s)
      end
    end

    #
    # Accesstype literal
    #
    define_parser do
      rule(:accesstype_literal) do
        (kw_rw1 | kw_na | kw_rw | kw_w1 | kw_wr | kw_r | kw_w)
          .as(:accesstype_literal) >> spaces?
      end
    end

    define_transformer do
      rule(accesstype_literal: simple(:t)) do
        AST::AccesstypeLiteral.new(t)
      end
    end

    #
    # Onreadtype literal
    #
    define_parser do
      rule(:onreadtype_literal) do
        (kw_rclr | kw_rset | kw_ruser)
          .as(:onreadtype_literal) >> spaces?
      end
    end

    define_transformer do
      rule(onreadtype_literal: simple(:t)) do
        AST::OnreadtypeLiteral.new(t)
      end
    end

    #
    # Onwritetype literal
    #
    define_parser do
      rule(:onwritetype_literal) do
        (
          kw_woset | kw_woclr | kw_wot | kw_wzs | kw_wzc |
          kw_wzt | kw_wclr | kw_wset | kw_wuser
        )
          .as(:onwritetype_literal) >> spaces?
      end
    end

    define_transformer do
      rule(onwritetype_literal: simple(:t)) do
        AST::OnwritetypeLiteral.new(t)
      end
    end

    #
    # Addressingtype literal
    #
    define_parser do
      rule(:addressingtype_literal) do
        (kw_compact | kw_regalign | kw_fullalign)
          .as(:addressingtype_literal) >> spaces?
      end
    end

    define_transformer do
      rule(addressingtype_literal: simple(:t)) do
        AST::AddressingtypeLiteral.new(t)
      end
    end

    #
    # Precedencetype literal
    #
    define_parser do
      rule(:precedencetype_literal) do
        (kw_hw | kw_sw).as(:precedencetype_literal) >> spaces?
      end
    end

    define_transformer do
      rule(precedencetype_literal: simple(:t)) do
        AST::PrecedencetypeLiteral.new(t)
      end
    end
  end
end
