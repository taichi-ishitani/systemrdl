# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Define
        def initialize(id, body)
          @id = id
          @body = replace_nl(body)
        end

        def process(context, _tokens)
          context.define_macro(@id, @body)
        end

        private

        def replace_nl(body)
          body.map do |token|
            case token.kind
            when :PP_NL then Token.new("\n", :NL, token.position)
            when :NL then Token.new('', :EOS, token.position)
            else token
            end
          end
        end
      end
    end
  end
end
