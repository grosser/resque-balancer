require 'resque'

module Resque
  module Plugins
    module Balancer
      def queues
        super.sort_by { |q| - weights[q].to_f } # TODO: nil = 1
      end

      # TODO: dynamic
      def weights
        @weights ||= begin
          weights = ENV['WEIGHTS'] || raise(KeyError, 'resque-balancer needs WEIGHTS to work')
          weights.split(',').map { |w| w.split(':') }.to_h
        end
      end
    end
  end
end

Resque::Worker.send(:prepend, Resque::Plugins::Balancer)
