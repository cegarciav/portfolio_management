# Portfolio Management

Solution to Fintual's Senior Software Engineer coding challenge.

## The challenge

> You're building a portfolio management module, part of a personal investments and trading app.
>
> Construct a simple Portfolio class that has a collection of Stocks. Assume each Stock has a
> "Current Price" method that receives the last available price. Also, the Portfolio class has a
> collection of "allocated" Stocks that represents the distribution of the Stocks the Portfolio is
> aiming (i.e. 40% META, 60% APPL).
>
> Provide a portfolio rebalance method to know which Stocks should be sold and which ones should be
> bought to have a balanced Portfolio based on the portfolio's allocation.
>
> Add documentation/comments to understand your thinking process and solution.

## Approach

A portfolio is **balanced** when each stock's share of the portfolio's total value equals its
target weight in the allocation. So `rebalance` thinks in money first and shares second:

1. Work out the value the portfolio should have: `target_total = total_value + cash`.
2. Work out how much money each stock should hold: `target_total * weight`.
3. Convert that to shares at the current price and subtract the shares already held:
   `trade = target_total * weight / current_price - shares_held`.

The result is `{ stock => shares }`: positive means **buy**, negative means **sell**. Only stocks
that need a trade are included, so `{}` means the portfolio is already balanced.

Design decisions:

- **Shares per stock as the output.** It's the minimum needed to answer "what to sell and what to
  buy", and it's easy to build on: the money involved is just `shares * current_price`.
- **Cash in and out.** `rebalance(cash: 1000)` invests a deposit and `rebalance(cash: -1000)`
  sells to cover a withdrawal, following the allocation. It defaults to `0`, a plain rebalance.
  Both use the same formula.
- **Fail fast.** Withdrawing more than the portfolio is worth raises `InsufficientFundsError`, and
  rebalancing without an allocation raises `Error`, before any trade is computed.
- **No side effects.** `rebalance` only answers a question; it doesn't modify the portfolio.
  Holdings and allocation are frozen.
- **`BigDecimal` for money and shares**, to avoid floating-point rounding errors.
- **One runtime dependency**: `bigdecimal`, which shipped with Ruby until 3.4.

## Assumptions

- A `Stock` has a unique identifier (its ticker symbol). Two `Stock` objects with the same symbol
  are the same stock.
- The challenge says the "Current Price" method *receives* the last available price. We read that
  as *returns* it: `stock.current_price` takes no arguments and returns the stock's latest price.
- Holdings are a collection of stocks *with the number of shares held*: without quantities, the
  portfolio's value can't be known.
- The allocation is a collection of stocks with a target weight each (`0.4` = 40% of the value),
  and the weights are positive and add up to 1. A stock that shouldn't be held is left out of the
  allocation instead of getting a weight of 0.
- A held stock that isn't in the allocation has a target of 0%, so it's sold entirely. An
  allocated stock that isn't held is bought from zero.
- **Fractional shares are allowed**, like most modern brokers and funds. Results are rounded to
  10 decimal places (`Portfolio::SHARE_PRECISION`), which is "good enough": callers are expected
  to round further to whatever their broker accepts.
- Trades happen at the current price, with no fees, taxes or price changes during execution.

## Next steps

- **Skip tiny trades**: only rebalance a stock when it drifts past a tolerance band (e.g. ±5%
  from its target), to avoid trades that cost more in fees than they fix.
- **Whole shares**: an optional rounding policy for brokers without fractional shares, with the
  resulting leftover cash reported.
- **Cash tracking**: keep a cash balance in the portfolio over time, instead of only passing a
  one-off `cash` amount to `rebalance`.

## LLM usage

**Why an LLM, and why Ruby.** I used Claude Code on purpose: I'm practicing delegating code
writing to an LLM while I own the problem definition, the design decisions and the review. The
decisions in this repo came out of that back-and-forth, and the whole conversation is in
[docs/llm-conversation.md](docs/llm-conversation.md). I chose Ruby because it's Fintual's main
stack, even though I haven't written it in years. I relied on the LLM for Ruby idioms and tooling,
and focused my own effort on the logic and on checking the result.

Solved with Claude Code (Claude Opus 5.5) and exported with its `/export` command. Local paths and
account details were replaced with `********`; nothing else was edited.

## Requirements

- Ruby 4.0 (see `.ruby-version`)
- Bundler

## Setup

```bash
bundle install
```

## Usage

```ruby
require_relative 'lib/portfolio_management'

meta = PortfolioManagement::Stock.new('META', 500)
aapl = PortfolioManagement::Stock.new('AAPL', 200)

portfolio = PortfolioManagement::Portfolio.new(
  holdings: { meta => 2, aapl => 5 },
  allocation: { meta => 0.4, aapl => 0.6 }
)
portfolio.total_value # => 2000

# META holds 1000 (50%) but should hold 800 (40%); AAPL holds 1000 but should hold 1200
portfolio.rebalance
# => { META => -0.4, AAPL => 1 }       sell 0.4 META, buy 1 AAPL

portfolio.rebalance(cash: 1000)         # deposit 1000
# => { META => 0.4, AAPL => 4 }

portfolio.rebalance(cash: -1000)        # withdraw 1000
# => { META => -1.2, AAPL => -2 }
```

(Values are `BigDecimal` and the keys are `Stock` objects; they're shown simplified here.)

Or play with it interactively:

```bash
bin/console
```

## Running tests and linter

```bash
bundle exec rspec     # tests (coverage report in coverage/)
bundle exec rubocop   # lint
bundle exec rake      # both
```
