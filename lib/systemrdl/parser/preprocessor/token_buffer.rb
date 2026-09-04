# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class TokenBuffer
        def initialize(tokens)
          @tokens = tokens.dup
        end

        def next_token(in_macro_body)
          while (token = @tokens.shift)
            next if !in_macro_body && token.kind == :NL

            return token
          end
        end
      end
    end
  end
end
