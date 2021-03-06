require 'redis'

class RRRDTool
  def initialize(opts)
    @buckets = opts[:buckets]
    @step = opts[:step]
    @debug = opts[:debug] || false

    @current = nil
    @db = Redis.new
  end

  def time_epoch; (Time.now.to_i / @step) % @buckets; end
  def epochs_ago(set, num)
    b = time_epoch-num
    b = (b < 0) ? @buckets + b : b

    "#{set}:#{b}"
  end

  def buckets(set)
    (0...@buckets).inject([]) {|a,v| a.push epochs_ago(set, v) }
  end

  def epoch(set)
    current_epoch = time_epoch
    last_epoch = @db.get("#{set}:epoch").to_i
    now = set + ":" + current_epoch.to_s

    if now != @current and current_epoch != last_epoch
      debug [:new_epoch, current_epoch]

      [(Time.now.to_i / @step - last_epoch).abs, @buckets].min.times do |n|
        clear_bucket(epochs_ago(set, n))
      end

      @current = now
      @db.set("#{set}:epoch", Time.now.to_i / @step)
    end

    @current
  end
  alias :check_epoch :epoch

  def union_epochs(set)
    check_epoch(set)

    debug [:union_epochs, buckets(set)]
    @db.zunion("#{set}:union", buckets(set))
  end

  def score(set, key)
    union_epochs(set)

    buckets(set).each {|b| debug [b, @db.zscore(b, key)]}
    @db.zscore("#{set}:union", key).to_i
  end

  def incr(set, key, val=1)
    debug [:zincrby, epoch(set), val, key]
    @db.zincrby(epoch(set), val, key).to_i
  end

  def set(set, key, val)
    debug [:zadd, epoch(set), val, key]
    @db.zadd(epoch(set), val, key)
  end

  def first(set, num, options = {})
    union_epochs(set)
    e = @db.zrevrange("#{set}:union", 0, num, options)
    options.key?(:with_scores) ? Hash[*e] : e
  end

  def last(set, num, options = {})
    union_epochs(set)
    e = @db.zrange("#{set}:union", 0, num, options)
    options.key?(:with_scores) ? Hash[*e] : e
  end

  def rank(set, key)
    union_epochs(set)
    @db.zrevrank("#{set}:union", key)
  end

  def stats(set)
    stats = {}

    union_epochs(set)
    stats[:buckets] = @buckets
    stats[:unique_keys] = @db.zcard("#{set}:union")
    stats[:key_count] = (0...@buckets).inject({}) do |h,v|
      h[v] = @db.zcard("#{set}:#{v}")
      h
    end

    stats
  end

  def delete(set, key)
    buckets(set).each do |b|
      @db.zrem(b, key)
    end
  end

  def clear(set)
    buckets(set).each do |b|
      clear_bucket(b)
    end
  end

  def flushdb; @db.flushdb; end

  private

    def clear_bucket(b)
      debug [:clearing_epoch, b]
      @db.zremrangebyrank(b, 0, 2**32)
    end

    def debug(msg); p msg if @debug; end
end
