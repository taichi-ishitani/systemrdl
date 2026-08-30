# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Define
        def initialize(id)
          @id = id
        end

        def process(context, _tokens)
          context.define_macro(@id, '')
        end
      end
    end
  end
end
