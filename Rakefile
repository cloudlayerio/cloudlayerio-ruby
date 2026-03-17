# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc 'Generate YARD documentation'
task :yard do
  sh 'yard doc'
end

desc 'Build the gem'
task :build do
  sh 'gem build cloudlayerio.gemspec'
end

task default: :spec
