# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      MacroDefinition = Data.define(:params, :body)

      class Define
        def initialize(id, params, body)
          @id = id
          @definition = macro_definition(params, body)
        end

        def process(context, _tokens)
          context.define_macro(@id, @definition)
        end

        private

        def macro_definition(params, body)
          body_tokens = body.map do |token|
            case token.kind
            when :PP_NL then Token.new("\n", :NL, token.position)
            when :NL then Token.new('', :EOS, token.position)
            else token
            end
          end

          MacroDefinition.new(
            params: params&.map(&:to_sym),
            body: body_tokens
          )
        end
      end
    end
  end
end
