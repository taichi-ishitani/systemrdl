# frozen_string_literal: true

module SystemRDL
  module Parser
    module Preprocessor
      class Include
        def initialize(filename)
          @filename = filename
        end

        def process(context, tokens)
          path = find_include_file(context)
          include_tokens = load_include_file(context, path)
          tokens.concat(include_tokens)
        end

        private

        def find_include_file(context)
          filename =
            if RUBY_VERSION >= '4.0'
              @filename.text.strip('"')
            else
              @filename.text[1..-2]
            end

          [*context.incdirs, '.'].each do |incdir|
            path = File.join(incdir, filename)
            return path if File.file?(path)
          end

          # TODO
          # report error
        end

        def load_include_file(context, path)
          source = Source.new(File.read(path), path, 1, 1)
          Preprocessor.process(source, context, remove_eos: true)
        end
      end
    end
  end
end
