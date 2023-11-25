# frozen_string_literal: true

require_relative 'lib/systemrdl/version'

Gem::Specification.new do |spec|
  spec.name = 'systemrdl'
  spec.version = SystemRDL::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['taichi730@gmail.com']

  spec.summary = 'SystemRDL parser for Ruby'
  spec.homepage = 'https://github.com/taichi-ishitani/systemrdl'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z lib LICENSE.txt *.md`.split("\x0")
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'ast', '>= 2.4.2'
  spec.add_runtime_dependency 'facets', '>= 3.0.0'
  spec.add_runtime_dependency 'parslet', '>= 2.0.0'
end
