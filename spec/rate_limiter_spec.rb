require 'discordrb'

# alias so I don't have to type it out every time...
BUCKET = Discordrb::Commands::Bucket
RATELIMITER = Discordrb::Commands::RateLimiter

describe Discordrb::Commands::Bucket do
  describe 'rate_limited?' do
    it 'should not rate limit one request' do
      BUCKET.new(1, 5, 2).rate_limited?(:a).should be_falsy
      BUCKET.new(nil, nil, 2).rate_limited?(:a).should be_falsy
      BUCKET.new(1, 5, nil).rate_limited?(:a).should be_falsy
      BUCKET.new(0, 1, nil).rate_limited?(:a).should be_falsy
      BUCKET.new(0, 1_000_000_000, 500_000_000).rate_limited?(:a).should be_falsy
    end

    it 'should fail to initialize with invalid arguments' do
      expect { BUCKET.new(0, nil, 0) }.to raise_error(ArgumentError)
    end

    it 'should fail to rate limit something invalid' do
      expect { BUCKET.new(1, 5, 2).rate_limited?("can't RL a string!") }.to raise_error(ArgumentError)
    end

    it 'should rate limit one request over the limit' do
      b = BUCKET.new(1, 5, nil)
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_truthy
    end

    it 'should rate limit multiple requests that are over the limit' do
      b = BUCKET.new(3, 5, nil)
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_truthy
    end

    it 'should not rate limit after the limit ran out' do
      b = BUCKET.new(2, 5, nil)
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_truthy
      b.rate_limited?(:a, Time.now + 4).should be_truthy
      b.rate_limited?(:a, Time.now + 5).should be_falsy
    end

    it 'should reset the limit after it ran out' do
      b = BUCKET.new(2, 5, nil)
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_falsy
      b.rate_limited?(:a).should be_truthy
      b.rate_limited?(:a, Time.now + 5).should be_falsy
      b.rate_limited?(:a, Time.now + 5.01).should be_falsy
      b.rate_limited?(:a, Time.now + 5.02).should be_truthy
    end
  end
end