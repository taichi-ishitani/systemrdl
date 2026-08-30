# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class SourceDescription
        def initialize(items)
          @items = items
        end

        def process(context, tokens)
          @items.each { |item| item.process(context, tokens) }
        end
      end
    end
  end
end
