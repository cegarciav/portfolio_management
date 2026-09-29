# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

module PortfolioManagement
  class Error < StandardError; end
end

require_relative 'portfolio_management/version'
require_relative 'portfolio_management/stock'
