# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

CLEAN << 'coverage'
CLEAN << 'doc'

Minitest::TestTask.create :test do |t|
  t.test_prelude = 'require "simplecov_prelude"'
end

desc 'Run the testsuite and collect code coverage'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['test'].execute
end

unless ENV.key?('CI')
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)

  require 'bump/tasks'

  desc 'generate SystemRDL parser'
  file 'lib/systemrdl/parser/generated_parser.rb' => 'lib/systemrdl/parser/systemrdl.y' do
    sh 'bundle exec racc lib/systemrdl/parser/systemrdl.y -v -F -t -o lib/systemrdl/parser/generated_parser.rb'
  end

  task test: ['lib/systemrdl/parser/generated_parser.rb']
end

require 'rdoc/task'
RDoc::Task.new do |t|
  t.rdoc_dir = 'doc'
end

task default: :test
