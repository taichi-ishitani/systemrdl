# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class RdlTokens
        def initialize(tokens)
          @tokens = tokens
        end

        def process(_context, tokens)
          tokens.concat(@tokens)
        end
      end
    end
  end
end
