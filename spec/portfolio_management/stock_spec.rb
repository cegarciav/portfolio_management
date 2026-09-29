# frozen_string_literal: true

RSpec.describe PortfolioManagement::Stock do
  subject(:stock) { described_class.new('meta', 500.25) }

  it 'normalizes the symbol' do
    expect(stock.symbol).to eq('META')
  end

  it 'returns its current price as a BigDecimal' do
    expect(stock.current_price).to eq(BigDecimal('500.25'))
  end

  it 'rejects non-positive prices' do
    expect { described_class.new('META', 0) }.to raise_error(ArgumentError)
  end

  it 'is equal to another stock with the same symbol' do
    expect(stock).to eql(described_class.new('META', 1))
  end
end
