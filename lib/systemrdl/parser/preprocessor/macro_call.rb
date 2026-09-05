# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class MacroCall
        def initialize(id, args, l_paren, r_paren)
          @id = id
          @args = append_eos(args)
          @l_paren = l_paren
          @r_paren = r_paren
        end

        def process(context, tokens)
          definition = context.find_macro(@id)
          args = process_args(definition, context)

          return if definition.body.size == 1 # body contains EOS only

          macro_tokens = process_macro_body(definition, args, context)
          tokens.concat(macro_tokens)
        end

        private

        def append_eos(args)
          args&.each { |arg| arg << eos_token(arg) }
        end

        def eos_token(arg)
          last_text = arg.last.text
          last_pos = arg.last.position
          line, column = Utils.calc_next_position(last_text, last_pos.line, last_pos.column)

          eos_pos = Position.new(last_pos.filename, line, column)
          Token.new('', :EOS, eos_pos)
        end

        def process_args(definition, context)
          n_params = definition.params&.size || 0
          n_args = @args&.size || 0
          if n_args != n_params
            # TODO
            # report error
          elsif n_params == 0
            return
          end

          definition.params.zip(@args).to_h do |param, arg|
            [param, process_arg(arg, context)]
          end
        end

        def process_arg(arg, context)
          Preprocessor.process_tokens(arg, context, remove_eos: true)
        end

        def process_macro_body(definition, args, context)
          body = apply_args(definition, args)
          Preprocessor.process_tokens(body, context, remove_eos: true)
        end

        def apply_args(definition, args)
          definition.body.flat_map do |token|
            next token if token.kind != :SIMPLE_ID

            arg = args[token.to_sym]
            next token unless arg

            arg
          end
        end
      end
    end
  end
end
