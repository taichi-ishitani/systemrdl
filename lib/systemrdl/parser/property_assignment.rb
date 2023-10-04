# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:prop_keyword) do
        kw_sw | kw_hw | kw_rclr | kw_rset | kw_woclr | kw_woset
      end

      rule(:prop_assignment) do
        prop_default >> prop_lhs.as(:prop_lhs) >> spaces? >>
          (spaced('=') >> prop_rhs.as(:prop_rhs)).maybe >> spaced(';')
      end

      rule(:encode_assignment) do
        prop_default >> prop_encode_lhs.as(:prop_lhs) >> spaces? >>
          spaced('=') >> prop_encode_rhs.as(:prop_rhs) >> spaced(';')
      end

      rule(:prop_modifier) do
        prop_default >> prop_mod.as(:prop_mod) >>
          id.as(:prop_id) >> spaces? >> spaced(';')
      end

      rule(:post_prop_assignment) do
        define_property_ref(prop_lhs).as(:prop_lhs) >> spaces? >>
          (spaced('=') >> prop_rhs.as(:prop_rhs)).maybe >> spaced(';')
      end

      rule(:post_encode_assignment) do
        define_property_ref(prop_encode_lhs).as(:prop_lhs) >> spaces? >>
          spaced('=') >> prop_encode_rhs.as(:prop_rhs) >> spaced(';')
      end

      rule(:property_assignment) do
        post_encode_assignment | post_prop_assignment |
          encode_assignment | prop_assignment | prop_modifier
      end

      private

      def prop_default
        (kw_default.as(:prop_default) >> spaces).maybe
      end

      def prop_lhs
        prop_keyword.as(:prop_keyword) | id
      end

      def prop_rhs
        precedencetype_literal | constant_expression
      end

      def prop_encode_lhs
        kw_encode.as(:prop_keyword)
      end

      def prop_encode_rhs
        id >> spaces?
      end

      def prop_mod
        (kw_posedge | kw_negedge | kw_bothedge | kw_level | kw_nonsticky) >> spaces
      end
    end

    define_transformer do
      rule(prop_keyword: simple(:k)) do
        AST::ID.new(k.position, k.str.to_sym)
      end

      rule(prop_default: simple(:d), prop_lhs: simple(:l)) do
        AST::PropertyAssignment.new(d.position, l, nil, true)
      end

      rule(prop_lhs: simple(:l)) do
        AST::PropertyAssignment.new(l.position, l, nil, false)
      end

      rule(prop_default: simple(:d), prop_lhs: simple(:l), prop_rhs: simple(:r)) do
        AST::PropertyAssignment.new(d.position, l, r, true)
      end

      rule(prop_lhs: simple(:l), prop_rhs: simple(:r)) do
        AST::PropertyAssignment.new(l.position, l, r, false)
      end

      rule(prop_default: simple(:d), prop_mod: simple(:m), prop_id: simple(:i)) do
        AST::PropertyModifier.new(d.position, i, m.str.to_sym, true)
      end

      rule(prop_mod: simple(:m), prop_id: simple(:i)) do
        AST::PropertyModifier.new(m.position, i, m.str.to_sym, false)
      end
    end
  end
end
