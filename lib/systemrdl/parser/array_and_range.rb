# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:range) do
        bracketed(
          constant_expression.as(:range_begin) >>
            spaced(':').ignore >> constant_expression.as(:range_end),
          '[', ']'
        )
      end

      rule(:array) do
        bracketed(constant_expression, '[', ']').repeat(1)
      end
    end

    define_transformer do
      rule(range_begin: simple(:b), range_end: simple(:e)) do
        [b, e]
      end
    end
  end
end
