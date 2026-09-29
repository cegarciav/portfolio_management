# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

module PortfolioManagement
  class Error < StandardError; end

  # Raised when a withdrawal is larger than the portfolio's current value.
  class InsufficientFundsError < Error; end
end

require_relative 'portfolio_management/version'
require_relative 'portfolio_management/stock'
require_relative 'portfolio_management/portfolio'
