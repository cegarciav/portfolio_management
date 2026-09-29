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
  end
end
