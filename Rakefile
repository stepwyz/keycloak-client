# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :integration do
  # NB: RSpec::Core::RakeTask blocks run at Rakefile load time, so any ENV
  # mutations inside them stack and the last definition wins. Set the env in a
  # plain action instead, so the right mode applies at invoke time. Rake runs a
  # task's actions in definition order and RSpec::Core::RakeTask appends its
  # own, so the env action has to be declared *first* — otherwise rspec runs
  # before KC_LIVE is set and every integration spec is silently filtered out.

  task :password do
    ENV['KC_LIVE'] = '1'
    ENV['KC_AUTH'] = 'password'
  end
  RSpec::Core::RakeTask.new(:password) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end

  task :service do
    ENV['KC_LIVE'] = '1'
    ENV['KC_AUTH'] = 'service'
  end
  RSpec::Core::RakeTask.new(:service) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
    # No master-realm service account by default, so cross-realm specs skip.
    t.rspec_opts = '--tag ~master_admin'
  end
end

desc 'Run the integration suite against a live Keycloak under both auth modes'
task :integration do
  failed = []
  %w[password service].each do |mode|
    ENV['KC_LIVE'] = '1'
    ENV['KC_AUTH'] = mode
    begin
      Rake::Task["integration:#{mode}"].reenable
      Rake::Task["integration:#{mode}"].invoke
    rescue SystemExit, StandardError => e
      failed << "#{mode}: #{e.class}"
    end
  end
  abort "Integration runs failed: #{failed.join(', ')}" if failed.any?
end

desc 'Run the unit and integration suites with coverage, merged into coverage/'
task :coverage do
  require 'json'

  ENV['COVERAGE'] = '1'
  minimum = Float(ENV.fetch('COVERAGE_MIN', 99))

  rm_rf 'coverage'
  Rake::Task[:spec].invoke
  Rake::Task[:integration].invoke

  # Each rspec process merges into the same resultset, so the last one to
  # finish records the combined totals. Enforce the threshold on those rather
  # than in-process, where a partial run would trip it.
  result = JSON.parse(File.read('coverage/.last_run.json'))['result']
  puts "\nMerged coverage report: coverage/index.html"
  puts format('Line coverage: %.2f%%  Branch coverage: %.2f%%', result['line'], result['branch'])

  if result['line'] < minimum
    abort format('Line coverage %.2f%% is below the %.2f%% minimum.', result['line'], minimum)
  end
end

task default: :spec
