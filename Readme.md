Balances queues by usage time, to prevent high priority queues from starving all others.

Install
=======

```Bash
gem install resque-balancer

require 'resque-balancer' in your Rakefile
```

Usage
=====

```Ruby
# high can use 50x the time low uses and 2.5x the time medium uses
# by default all queues get the same usage allowance
export BALANCER_WEIGHTS=high:5,medium:2,low:0.1

# clear usage counts every X seconds to make queues that were super busy in the past get a fresh start
# by default this will happen every 10 minutes
export BALANCER_RESET_INTERVAL=60

rake resque:work
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/resque-balancer.png)](https://travis-ci.org/grosser/resque-balancer)
