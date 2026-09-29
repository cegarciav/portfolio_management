# frozen_string_literal: true

require 'simplecov'
SimpleCov.start { add_filter '/spec/' }

require_relative '../lib/portfolio_management'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :random
  Kernel.srand config.seed
end
