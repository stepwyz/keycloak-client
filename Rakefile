# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :integration do
  # NB: RSpec::Core::RakeTask blocks run at Rakefile load time, so any ENV
  # mutations inside them stack and the last definition wins. Set the env
  # *inside* the task action so the right mode applies at invoke time.

  RSpec::Core::RakeTask.new(:password) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
  task :password do
    ENV['KC_LIVE'] = '1'
    ENV['KC_AUTH'] = 'password'
  end

  RSpec::Core::RakeTask.new(:service) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
    # No master-realm service account by default, so cross-realm specs skip.
    t.rspec_opts = '--tag ~master_admin'
  end
  task :service do
    ENV['KC_LIVE'] = '1'
    ENV['KC_AUTH'] = 'service'
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

task default: :spec
