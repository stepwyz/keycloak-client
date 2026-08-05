# frozen_string_literal: true

# Coverage is opt-in: set COVERAGE=1 (or run `rake coverage`).
#
# The suite runs in up to three separate rspec processes — unit, integration in
# password mode, integration in service mode — so each one writes its results
# under a distinct command name and SimpleCov merges them into a single report.
# No per-process threshold is enforced here: any single run covers only part of
# the gem. `rake coverage` checks the merged total once every run has finished.
return unless ENV['COVERAGE'] == '1'

require 'simplecov'

SimpleCov.start do
  enable_coverage :branch

  command_name(
    if ENV['KC_LIVE'] == '1'
      "integration-#{ENV.fetch('KC_AUTH', 'password')}"
    else
      'unit'
    end
  )

  use_merging true
  merge_timeout 3600

  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Client',     'lib/keycloak-client/admin_client.rb'
  add_group 'Resources',  'lib/keycloak-client/resources'
  add_group 'Middleware', 'lib/middleware'
end
