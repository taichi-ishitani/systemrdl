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

  {
    parser: ['systemrdl.y', 'generated_parser.rb'],
    preprocessor: ['preprocessor/preprocessor.y', 'preprocessor/generated_preprocessor.rb']
  }.each do |kind, (input, result)|
    input_path = "lib/systemrdl/parser/#{input}"
    result_path = "lib/systemrdl/parser/#{result}"

    desc "generate SystemRDL #{kind}"
    file result_path => input_path do
      sh "bundle exec racc #{input_path} -v -F -t -o #{result_path}"
    end
  end

  desc 'Run Racc and generate SystemRDL parser and preprocessor'
  task racc: [
    'lib/systemrdl/parser/generated_parser.rb',
    'lib/systemrdl/parser/preprocessor/generated_preprocessor.rb'
  ]

  task test: [:racc]
end

require 'rdoc/task'
RDoc::Task.new do |t|
  t.rdoc_dir = 'doc'
end

task default: :test
