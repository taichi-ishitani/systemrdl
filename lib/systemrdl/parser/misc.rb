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
        space.repeat.ignore
      end

      private

      def spaced(string)
        str(string) >> spaces?
      end

      def bracketed(atom, bra = '(', cket = ')')
        b = str(bra).ignore >> spaces?
        c = str(cket).ignore >> spaces?

        atom && (b >> atom >> c) || b >> c
      end

      def listed(atom, separator = ',')
        (atom >> spaced(separator)).repeat >> atom
      end
    end

    define_transformer do
      private

      def fetch_values(hash, *keys)
        hash.fetch_values(*keys) { nil }
      end
    end
  end
end
