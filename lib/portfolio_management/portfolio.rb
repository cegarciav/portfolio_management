# frozen_string_literal: true

module PortfolioManagement
  # A portfolio holds some shares of each stock (its holdings) and has a
  # target allocation: the fraction of the total value each stock should
  # represent, e.g. { META => 0.4, AAPL => 0.6 }.
  class Portfolio
    attr_reader :holdings, :allocation

    # holdings:   Hash of Stock => number of shares
    # allocation: Hash of Stock => target weight (must add up to 1)
    def initialize(holdings: {}, allocation: {})
      @holdings = holdings.transform_values(&:to_d).freeze
      @allocation = allocation.transform_values(&:to_d).freeze
      validate!
    end

    def stocks
      (holdings.keys + allocation.keys).uniq
    end

    def shares_of(stock)
      holdings.fetch(stock, BigDecimal('0'))
    end

    def value_of(stock)
      shares_of(stock) * stock.current_price
    end

    def total_value
      holdings.keys.sum(BigDecimal('0')) { |stock| value_of(stock) }
    end

    private

    def validate!
      raise ArgumentError, 'shares cannot be negative' if holdings.values.any?(&:negative?)
      raise ArgumentError, 'weights cannot be negative' if allocation.values.any?(&:negative?)
      return if allocation.empty? || allocation.values.sum == 1

      raise ArgumentError, 'allocation weights must add up to 1'
    end
  end
end
