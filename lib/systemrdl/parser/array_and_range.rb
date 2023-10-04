# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:array) do
        array_element.repeat(1)
      end

      private

      def array_element
        bracketed(constant_expression, '[', ']')
      end
    end
  end
end
