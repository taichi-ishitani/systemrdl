# frozen_string_literal: true

module SystemRDL
  class Parser
    define_parser do
      rule(:spaces) do
        match('[ \t\n\r]').repeat(1)
      end

      rule(:spaces?) do
        spaces.maybe
      end
    end
  end
end
