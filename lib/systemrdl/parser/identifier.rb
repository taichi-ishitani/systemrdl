# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:simple_identifier) do
        (any_keyword | any_reserved_word).absent? >>
          (match('[_a-zA-Z]') >> match('\\w').repeat)
      end

      rule(:escaped_identifier) do
        str('\\') >> match('[_0-9a-zA-Z]') >> match('\\w').repeat
      end

      rule(:id) do
        (simple_identifier | escaped_identifier).as(:identifer)
      end

      rule(:this_keyword) do
        kw_this.as(:this_keyword) >> spaces?
      end
    end

    define_transformer do
      rule(identifer: simple(:id)) do
        AST::ID.new(id)
      end

      rule(this_keyword: simple(:id)) do
        AST::ThisKeyword.new(id)
      end
    end
  end
end
