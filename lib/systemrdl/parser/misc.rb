# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:space) do
        match('[ \t\n\r]')
      end

      rule(:spaces) do
        space.repeat(1).ignore
      end

      rule(:spaces?) do
        space.maybe.ignore
      end

      private

      def spaced(string)
        str(string) >> spaces?
      end

      def bracketed(atom, bra = '(', cket = ')')
        str(bra).ignore >> spaces? >> atom >> spaces? >> str(cket).ignore >> spaces?
      end
    end
  end
end
