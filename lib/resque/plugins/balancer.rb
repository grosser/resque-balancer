require 'resque'

module Resque
  module Plugins
    module Balancer

    end
  end
end

Resque::Worker.send(:prepend, Resque::Plugins::Balancer)
