# frozen_string_literal: true

module PortfolioManagement
  # A stock identified by its ticker symbol, e.g. "META".
  #
  # The challenge says to assume each Stock can tell its last available price,
  # so here it's simply given at construction time. In a real app this would
  # come from a market-data provider.
  class Stock
    attr_reader :symbol, :current_price

    def initialize(symbol, current_price)
      @symbol = symbol.to_s.upcase
      @current_price = current_price.to_d
      raise ArgumentError, 'current_price must be positive' unless @current_price.positive?
    end

    # Two Stock objects with the same symbol are the same stock, so they can
    # be used interchangeably as Hash keys (holdings, allocation).
    def ==(other)
      other.is_a?(Stock) && symbol == other.symbol
    end
    alias eql? ==

    def hash
      symbol.hash
    end
  end
end
