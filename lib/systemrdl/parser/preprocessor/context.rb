# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Context
        def initialize
          @macros = {}
        end

        def define_macro(id, body)
          @macros[id.to_sym] = body
        end

        def macor_defined?(id)
          @macros.key?(id.to_sym)
        end
      end
    end
  end
end
