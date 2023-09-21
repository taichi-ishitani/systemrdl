# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bump/tasks'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

desc 'Run all RSpec code exmaples and collect code coverage'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['spec'].execute
end

task default: :spec
