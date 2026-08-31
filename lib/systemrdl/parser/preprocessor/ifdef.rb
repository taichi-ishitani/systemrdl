# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Ifdef
        def initialize(if_branch, elsif_branches, else_branch)
          @if_branch = if_branch
          @elsif_branches = elsif_branches
          @else_branch = else_branch
        end

        def process(context, tokens)
          if_branches.each do |(condition, body)|
            next unless context.macro_defined?(condition)

            return body.process(context, tokens)
          end

          @else_branch&.process(context, tokens)
        end

        private

        def if_branches
          branches = [@if_branch]
          branches.concat(@elsif_branches) if @elsif_branches
          branches
        end
      end
    end
  end
end
