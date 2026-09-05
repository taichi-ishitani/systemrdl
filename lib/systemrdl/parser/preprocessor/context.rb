# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Context
        def initialize(incdirs, debug)
          @macros = {}
          @incdirs = incdirs
          @debug = debug
        end

        attr_reader :incdirs
        attr_reader :debug

        def define_macro(id, definition)
          @macros[id.to_sym] = definition
        end

        def undef_macro(id)
          @macros.delete(id.to_sym)
        end

        def macro_defined?(id)
          @macros.key?(id.to_sym)
        end

        def find_macro(id)
          unless macro_defined?(id)
            # todo
            # report error
          end

          @macros[id.to_sym]
        end
      end
    end
  end
end
