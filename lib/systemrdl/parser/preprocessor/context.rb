# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Context
        def initialize(incdirs, include_limit, debug)
          @macros = {}
          @incdirs = incdirs
          @include_limit = include_limit
          @include_depth = 0
          @debug = debug
        end

        attr_reader :incdirs
        attr_reader :include_limit
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
          @macros[id.to_sym]
        end

        def push_include
          @include_depth += 1
        end

        def pop_include
          @include_depth -= 1
        end

        def reach_include_limit?
          @include_depth >= @include_limit
        end
      end
    end
  end
end
