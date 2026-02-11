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
require_relative 'systemrdl/evaluator/processor'
require_relative 'systemrdl/evaluator'

module SystemRDL
end
