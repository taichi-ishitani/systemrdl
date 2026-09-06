# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Include
        include RaisePreprocessError

        def initialize(filename)
          @filename = filename
        end

        def process(context, tokens)
          filename = unquoted_filename
          if context.reach_include_limit?
            message = "include nesting too deep: #{filename} limit #{context.include_limit}"
            raise_preprocess_error message, @filename.position
          end

          path = find_include_file(context, filename)
          include_tokens = load_include_file(context, path)
          tokens.concat(include_tokens)
        end

        private

        def unquoted_filename
          if RUBY_VERSION >= '4.0'
            @filename.text.strip('"')
          else
            @filename.text[1..-2]
          end
        end

        def find_include_file(context, filename)
          [*context.incdirs, '.'].each do |incdir|
            path = File.join(incdir, filename)
            return path if File.file?(path)
          end

          message = "include file not found: #{filename}"
          raise_preprocess_error message, @filename.position
        end

        def load_include_file(context, path)
          context.push_include
          source = Source.new(File.read(path), path, 1, 1)
          tokens = Preprocessor.process(source, context, remove_eos: true)
          context.pop_include

          tokens
        end
      end
    end
  end
end
