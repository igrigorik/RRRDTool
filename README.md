# RRRDTool

Implements a [round-robin database](http://en.wikipedia.org/wiki/RRDtool) (circular buffer) pattern on top of Redis sorted sets. Ideal for answering top/last N queries in (almost) fixed (memory) space - actual footprint depends on the number of unique keys you are tracking. Specify the period and precision (step) of each collection bucket, and RRRDTool will do the rest.

Memory footprint will be limited to number of buckets * number of keys in each. New samples will be automatically placed into correct epoch/bucket.

## Store up to 5s worth of samples, in 1s buckets:
    rr = RRRDTool.new(:step => 1, :buckets => 5)

    rr.set("namespace", "key", 1)
    rr.incr("namespace", "key", 5)
    p rr.score("namespace", "key")  # => 6

    sleep (1)

    rr.incr("namespace", "key")
    p rr.score("namespace", "key")  # => 7
    p rr.first("namespace", 1, :with_scores => true) # => {"key"=>"7"}

    sleep(4)

    p rr.score("namespace", "key")  # => 1
    p rr.stats("namespace")         # => {:buckets=>5, :unique_keys=>1, :key_count=>{0=>0, 1=>0, 2=>0, 3=>1, 4=>0}}

    # find out high-to-low rank of a key across all epochs
    p rr.rank("namespace", "key")   # => 0

# License

(The MIT License)

Copyright (c) 2010 Ilya Grigorik

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.