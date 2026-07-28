# frozen_string_literal: true

require 'strscan'
require 'ast'

require_relative 'systemrdl/version'
require_relative 'systemrdl/error'
require_relative 'systemrdl/parser/token'
require_relative 'systemrdl/parser/scanner'
require_relative 'systemrdl/parser/node'
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
require_relative 'systemrdl/evaluator/array_component'
require_relative 'systemrdl/evaluator/container_component'
require_relative 'systemrdl/evaluator/field'
require_relative 'systemrdl/evaluator/reg'
require_relative 'systemrdl/evaluator/regfile'
require_relative 'systemrdl/evaluator/addrmap'
require_relative 'systemrdl/evaluator/root'
require_relative 'systemrdl/evaluator/processor'
require_relative 'systemrdl/evaluator'
require_relative 'systemrdl/model/value'
require_relative 'systemrdl/model/instance'
require_relative 'systemrdl/model'

module SystemRDL
  module_function

  def compile_files(*files)
    files.flat_map { |file| compile_file(file) }
  end

  def compile_file(file)
    File.open(file) { |fp| compile(fp, filename: file) }
  end

  def compile(string_or_io, filename: 'unknown')
    rdl =
      if string_or_io.is_a?(::String)
        string_or_io
      else
        string_or_io.read
      end
    ast = Parser.parse(rdl, filename:)
    root = Evaluator.evaluate(ast)
    Model.build(root)
  end
end
