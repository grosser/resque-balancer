require 'resque'

module Resque
  module Plugins
    module Balancer
      # override
      # record start time
      def working_on(job)
        @balancer_start = [job, Time.now]
        super
      end

      # override
      # record how much time the job used
      def done_working
        job, start = @balancer_start
        usage = (Time.now.to_f - start.to_f) / balancer_weights[job.queue]
        balancer_usage[job.queue] += usage
        super
      end

      # override
      # - prefer queues that were used the least
      # - prefer queues with high weight
      def queues
        balaner_reset_usage_after_interval
        super.sort_by { |q| [balancer_usage[q], -balancer_weights[q]] }
      end

      def balancer_usage
        @balancer_usage ||= Hash.new(0.0)
      end

      def balancer_weights
        @balancer_weights ||= begin
          weights = ENV['BALANCER_WEIGHTS'].to_s.split(',')
          weights.each_with_object(Hash.new(1)) do |w, all|
            name, weight = w.split(':', 2)
            all[name] = weight.to_f if weight
          end
        end
      end

      # every x seconds reset the usage so busy jobs get a new chance of behaving
      def balaner_reset_usage_after_interval
        now = Time.now.to_f
        @balancer_last_reset ||= now
        interval = (ENV['BALANCER_RESET_INTERVAL'] || '600').to_f
        if @balancer_last_reset + interval < now
          balancer_usage.clear
          @balancer_last_reset = now
        end
      end
    end
  end
end

Resque::Worker.send(:prepend, Resque::Plugins::Balancer)
