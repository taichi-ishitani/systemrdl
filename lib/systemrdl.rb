# frozen_string_literal: true

require 'ast'
require 'parslet'

require_relative 'systemrdl/version'
require_relative 'systemrdl/ast/base'
require_relative 'systemrdl/ast/identifier'
require_relative 'systemrdl/ast/literals'
require_relative 'systemrdl/ast/data_type'
require_relative 'systemrdl/ast/reference'
require_relative 'systemrdl/ast/expressions'
require_relative 'systemrdl/ast/property_assignment'
require_relative 'systemrdl/ast/component_definition'
require_relative 'systemrdl/parser'
require_relative 'systemrdl/parser/keywords'
require_relative 'systemrdl/parser/misc'
require_relative 'systemrdl/parser/identifier'
require_relative 'systemrdl/parser/literals'
require_relative 'systemrdl/parser/data_type'
require_relative 'systemrdl/parser/array_and_range'
require_relative 'systemrdl/parser/reference'
require_relative 'systemrdl/parser/expressions'
require_relative 'systemrdl/parser/property_assignment'
require_relative 'systemrdl/parser/component_definition'
require_relative 'systemrdl/parser/root'
