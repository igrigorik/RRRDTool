require 'lib/rrrdtool'

rr = RRRDTool.new(:step => 1, :buckets => 5)
rr.flushdb

rr.incr("namespace", "key")
rr.incr("namespace", "key", 5)
p rr.score("namespace", "key")  # => 6

sleep (1)

rr.incr("namespace", "key")
p rr.score("namespace", "key")  # => 7
p rr.first("namespace", 1, :with_scores => true) # => {"key"=>"7"}

sleep(4)

p rr.score("namespace", "key")  # => 1
p rr.stats("namespace")         # => {:buckets=>5, :unique_keys=>1, :key_count=>{0=>0, 1=>0, 2=>0, 3=>1, 4=>0}}