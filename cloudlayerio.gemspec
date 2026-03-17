# frozen_string_literal: true

require_relative 'lib/cloudlayerio/version'

Gem::Specification.new do |spec|
  spec.name = 'cloudlayerio'
  spec.version = CloudLayerio::VERSION
  spec.authors = ['CloudLayer.io']
  spec.email = ['support@cloudlayer.io']

  spec.summary = 'Official Ruby SDK for the CloudLayer.io document generation API'
  spec.description = 'Ruby client library for converting HTML, URLs, and templates to PDF ' \
                     'and images using the CloudLayer.io API'
  spec.homepage = 'https://github.com/cloudlayerio/cloudlayerio-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.required_rubygems_version = '>= 3.3.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/cloudlayerio/cloudlayerio-ruby',
    'changelog_uri' => 'https://github.com/cloudlayerio/cloudlayerio-ruby/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://cloudlayer.io/docs/sdk-ruby',
    'bug_tracker_uri' => 'https://github.com/cloudlayerio/cloudlayerio-ruby/issues',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir['lib/**/*', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  # Runtime: base64 was extracted from stdlib to a bundled gem in Ruby 3.4.
  # No-op on Ruby 3.1-3.3 (where it's a default gem), required on 3.4+.
  spec.add_dependency 'base64'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.23'
  spec.add_development_dependency 'yard', '~> 0.9'
end
