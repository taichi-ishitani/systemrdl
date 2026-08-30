# frozen_string_literal

module SystemRDL
  module Parser
    module Preprocessor
      class Root
        def initialize(source_description, eos)
          @source_description = source_description
          @eos = eos
        end

        def process(context, tokens)
          @source_description.process(context, tokens)
          tokens << @eos
        end
      end
    end
  end
end
