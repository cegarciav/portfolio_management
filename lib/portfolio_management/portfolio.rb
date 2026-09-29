# frozen_string_literal: true

module PortfolioManagement
  # A portfolio holds some shares of each stock (its holdings) and has a
  # target allocation: the fraction of the total value each stock should
  # represent, e.g. { META => 0.4, AAPL => 0.6 }.
  class Portfolio
    # Decimal places kept in rebalance results. Far finer than any real order
    # size, so it's "good enough": callers round further to whatever their
    # broker accepts (e.g. whole shares).
    SHARE_PRECISION = 10

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

    # Returns the trades needed so each stock's share of the portfolio value
    # matches its target weight, as { stock => shares }: positive means buy,
    # negative means sell. Stocks that need no trade are left out, so an empty
    # Hash means the portfolio is already balanced.
    #
    # cash: money added (positive) or withdrawn (negative) while rebalancing.
    #
    # The idea: work out how much money each stock *should* hold, convert that
    # into shares at the current price, and compare with the shares we hold:
    #
    #   target_total  = total_value + cash
    #   target_shares = target_total * weight / current_price
    #   trade         = target_shares - shares held
    #
    # Held stocks missing from the allocation have a target weight of 0, so
    # they are sold entirely. Fractional shares are allowed; see
    # SHARE_PRECISION. The portfolio itself is not modified.
    def rebalance(cash: 0)
      target_total = target_total_for(cash.to_d)

      stocks.each_with_object({}) do |stock, trades|
        trade = (target_shares(stock, target_total) - shares_of(stock)).round(SHARE_PRECISION)
        trades[stock] = trade unless trade.zero?
      end
    end

    private

    # Value the portfolio should have after rebalancing. Fails fast, before
    # computing any trade, if there's nowhere to put the money or the
    # withdrawal exceeds the portfolio's value at current prices.
    def target_total_for(cash)
      raise Error, 'cannot rebalance without an allocation' if allocation.empty?

      target_total = total_value + cash
      return target_total unless target_total.negative?

      raise InsufficientFundsError,
            "cannot withdraw #{(-cash).to_s('F')}, portfolio is worth #{total_value.to_s('F')}"
    end

    def target_shares(stock, target_total)
      target_total * allocation.fetch(stock, 0) / stock.current_price
    end

    def validate!
      raise ArgumentError, 'shares cannot be negative' if holdings.values.any?(&:negative?)
      raise ArgumentError, 'weights cannot be negative' if allocation.values.any?(&:negative?)
      return if allocation.empty? || allocation.values.sum == 1

      raise ArgumentError, 'allocation weights must add up to 1'
    end
  end
end
