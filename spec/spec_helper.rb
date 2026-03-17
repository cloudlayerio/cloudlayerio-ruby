# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  minimum_coverage 90
  add_filter '/spec/'
end

require 'cloudlayerio'
require 'webmock/rspec'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.order = :random
  config.filter_run_excluding :smoke
  config.example_status_persistence_file_path = 'tmp/rspec_status.txt'
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

# Load a raw fixture file as a string
def fixture(name)
  File.read(File.join(__dir__, 'fixtures', "#{name}.json"))
end

# Load and parse a fixture file as a hash
def fixture_hash(name)
  JSON.parse(fixture(name))
end
