require "bundler/setup"

require "single_cov"
SingleCov.setup :rspec

require "resque/balancer/version"
require "resque-balancer"

require "fakeredis/rspec"
