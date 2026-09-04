# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class MacroCall
        def initialize(id)
          @id = id
        end

        def process(context, tokens)
          macro_body = context.find_macro(@id)

          process_macro_body(macro_body, context, tokens)
        end

        private

        def process_macro_body(body, context, tokens)
          return if body.size == 1 # body contains EOS only

          macro_tokens = Preprocessor.process_tokens(body, context, remove_eos: true)
          tokens.concat(macro_tokens)
        end
      end
    end
  end
end
