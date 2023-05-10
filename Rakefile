# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :watch_tests do
  exec 'bundle exec guard'
end

task default: :spec