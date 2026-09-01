# frozen_string_literal: true

require 'strscan'
require 'ast'

require_relative 'systemrdl/version'
require_relative 'systemrdl/error'
require_relative 'systemrdl/parser/token'
require_relative 'systemrdl/parser/node'
require_relative 'systemrdl/parser/source'
require_relative 'systemrdl/parser/patterns'
require_relative 'systemrdl/parser/preprocessor/scanner'
require_relative 'systemrdl/parser/preprocessor/context'
require_relative 'systemrdl/parser/preprocessor/rdl_tokens'
require_relative 'systemrdl/parser/preprocessor/define'
require_relative 'systemrdl/parser/preprocessor/ifdef'
require_relative 'systemrdl/parser/preprocessor/include'
require_relative 'systemrdl/parser/preprocessor/source_description'
require_relative 'systemrdl/parser/preprocessor/root'
require_relative 'systemrdl/parser/preprocessor/generated_preprocessor'
require_relative 'systemrdl/parser/preprocessor/preprocessor'
require_relative 'systemrdl/parser/generated_parser'
require_relative 'systemrdl/parser/parser'
require_relative 'systemrdl/parser'
require_relative 'systemrdl/evaluator/value'
require_relative 'systemrdl/evaluator/common'
require_relative 'systemrdl/evaluator/list'
require_relative 'systemrdl/evaluator/literal'
require_relative 'systemrdl/evaluator/operation'
require_relative 'systemrdl/evaluator/instance'
require_relative 'systemrdl/evaluator/reference'
require_relative 'systemrdl/evaluator/property'
require_relative 'systemrdl/evaluator/property_assignment'
require_relative 'systemrdl/evaluator/builtin_properties'
require_relative 'systemrdl/evaluator/component_insts'
require_relative 'systemrdl/evaluator/component_definition'
require_relative 'systemrdl/evaluator/address_operation'
require_relative 'systemrdl/evaluator/address_allocation'
require_relative 'systemrdl/evaluator/inst_type_aware_component'
require_relative 'systemrdl/evaluator/array_component'
require_relative 'systemrdl/evaluator/container_component'
require_relative 'systemrdl/evaluator/block_component'
require_relative 'systemrdl/evaluator/field'
require_relative 'systemrdl/evaluator/reg'
require_relative 'systemrdl/evaluator/regfile'
require_relative 'systemrdl/evaluator/mem'
require_relative 'systemrdl/evaluator/addrmap'
require_relative 'systemrdl/evaluator/root'
require_relative 'systemrdl/evaluator/processor'
require_relative 'systemrdl/evaluator'
require_relative 'systemrdl/model/value'
require_relative 'systemrdl/model/instance'
require_relative 'systemrdl/model'

module SystemRDL
  class << self
    def compile(*filenames)
      __compile_multiple(filenames, :file_reader)
    end

    def compile_streams(streams)
      __compile_multiple(streams, :stream_reader)
    end

    def compile_source(rdl, filename: 'unknown')
      _, models = __compile(rdl, filename, nil, nil)
      models
    end

    private

    def file_reader(filename, &)
      File.open(filename) { |f| stream_reader(filename, f, &) }
    end

    def stream_reader(filename, stream)
      rdl = stream.read
      yield(rdl, filename)
    end

    def __compile_multiple(inputs, reader)
      _, models = inputs.inject([nil, nil]) do |(root, results), input|
        __send__(reader, *input) do |rdl, filename|
          __compile(rdl, filename, root, results)
        end
      end

      models
    end

    def __compile(rdl, filename, root, results)
      ast = Parser.parse(rdl, filename:)
      evaluated = Evaluator.evaluate(ast, root)
      models = Model.build(evaluated)

      if results
        results.concat(models)
        [evaluated, results]
      else
        [evaluated, models]
      end
    end
  end
end
