require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rake'
  task.requires << 'rubocop-rspec'
end
RSpec::Core::RakeTask.new(:spec)

task default: %i[rubocop spec]
