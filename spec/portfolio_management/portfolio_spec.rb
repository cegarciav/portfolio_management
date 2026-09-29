# frozen_string_literal: true

RSpec.describe PortfolioManagement::Portfolio do
  let(:meta) { PortfolioManagement::Stock.new('META', 500) }
  let(:aapl) { PortfolioManagement::Stock.new('AAPL', 200) }

  describe '#total_value' do
    it 'is zero for an empty portfolio' do
      expect(described_class.new.total_value).to eq(0)
    end

    it 'adds up the value of every holding' do
      portfolio = described_class.new(holdings: { meta => 2, aapl => 5 })
      expect(portfolio.total_value).to eq(2000)
    end
  end

  describe '#stocks' do
    it 'includes held and allocated stocks' do
      portfolio = described_class.new(holdings: { meta => 1 }, allocation: { aapl => 1 })
      expect(portfolio.stocks).to contain_exactly(meta, aapl)
    end
  end

  describe 'validation' do
    it 'rejects an allocation that does not add up to 1' do
      expect { described_class.new(allocation: { meta => 0.4, aapl => 0.5 }) }
        .to raise_error(ArgumentError, /add up to 1/)
    end

    it 'rejects negative shares' do
      expect { described_class.new(holdings: { meta => -1 }) }.to raise_error(ArgumentError)
    end

    it 'allows zero shares' do
      expect(described_class.new(holdings: { meta => 0 }).total_value).to eq(0)
    end

    it 'rejects zero weights' do
      expect { described_class.new(allocation: { meta => 1, aapl => 0 }) }
        .to raise_error(ArgumentError, /must be positive/)
    end
  end

  describe '#rebalance' do
    # META: 2 * 500 = 1000, AAPL: 5 * 200 = 1000, total 2000
    let(:holdings) { { meta => 2, aapl => 5 } }
    let(:portfolio) { described_class.new(holdings: holdings, allocation: { meta => 0.4, aapl => 0.6 }) }

    it 'sells overweight stocks and buys underweight ones' do
      # targets: META 800 (1.6 shares), AAPL 1200 (6 shares)
      expect(portfolio.rebalance).to eq(meta => BigDecimal('-0.4'), aapl => BigDecimal('1'))
    end

    it 'returns an empty Hash when already balanced' do
      balanced = described_class.new(holdings: { meta => 1.6, aapl => 6 }, allocation: portfolio.allocation)
      expect(balanced.rebalance).to eq({})
    end

    it 'sells every share of a held stock that is not allocated' do
      tsla = PortfolioManagement::Stock.new('TSLA', 100)
      portfolio = described_class.new(holdings: { meta => 2, tsla => 3 }, allocation: { meta => 1 })
      expect(portfolio.rebalance).to eq(meta => BigDecimal('0.6'), tsla => BigDecimal('-3'))
    end

    it 'buys allocated stocks that are not held' do
      portfolio = described_class.new(holdings: { meta => 2 }, allocation: { meta => 0.5, aapl => 0.5 })
      expect(portfolio.rebalance).to eq(meta => BigDecimal('-1'), aapl => BigDecimal('2.5'))
    end

    it 'invests deposited cash following the allocation' do
      # target total 3000: META 1200 (2.4 shares), AAPL 1800 (9 shares)
      expect(portfolio.rebalance(cash: 1000)).to eq(meta => BigDecimal('0.4'), aapl => BigDecimal('4'))
    end

    it 'sells to cover a withdrawal following the allocation' do
      # target total 1000: META 400 (0.8 shares), AAPL 600 (3 shares)
      expect(portfolio.rebalance(cash: -1000)).to eq(meta => BigDecimal('-1.2'), aapl => BigDecimal('-2'))
    end

    it 'sells everything when withdrawing the whole value' do
      expect(portfolio.rebalance(cash: -2000)).to eq(meta => BigDecimal('-2'), aapl => BigDecimal('-5'))
    end

    it 'raises when withdrawing more than the portfolio is worth' do
      expect { portfolio.rebalance(cash: -2000.01) }
        .to raise_error(PortfolioManagement::InsufficientFundsError, /worth 2000/)
    end

    it 'raises without an allocation' do
      expect { described_class.new(holdings: holdings).rebalance }
        .to raise_error(PortfolioManagement::Error, /without an allocation/)
    end

    it 'rounds shares to SHARE_PRECISION decimal places' do
      odd = PortfolioManagement::Stock.new('ODD', 3)
      portfolio = described_class.new(allocation: { odd => 1 })
      expect(portfolio.rebalance(cash: 1)).to eq(odd => BigDecimal('0.3333333333'))
    end

    it 'does not modify the holdings' do
      expect { portfolio.rebalance(cash: 500) }.not_to change(portfolio, :holdings)
    end
  end
end
