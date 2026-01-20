# frozen_string_literal: true

require 'strscan'
require 'ast'

require_relative 'systemrdl/version'
require_relative 'systemrdl/error'
require_relative 'systemrdl/ast/token'
require_relative 'systemrdl/ast/base'
require_relative 'systemrdl/ast/reference'
require_relative 'systemrdl/ast/array_range'
require_relative 'systemrdl/ast/literal'
require_relative 'systemrdl/ast/expression'
require_relative 'systemrdl/ast/id'
require_relative 'systemrdl/parser/raise_parse_error'
require_relative 'systemrdl/parser/scanner'
require_relative 'systemrdl/parser/generated_parser'
require_relative 'systemrdl/parser/parser'
require_relative 'systemrdl/parser'

module SystemRDL
end
