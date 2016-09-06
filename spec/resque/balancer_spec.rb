require "spec_helper"

SingleCov.covered! file: 'lib/resque/plugins/balancer.rb'

class InstantFeedbackLogger
  def self.debug(_); end
  def self.info(_); end
  def self.warn(message);  raise message end
  def self.error(message); raise message; end
  def self.fatal(message); raise message; end
end

Resque.logger = InstantFeedbackLogger

describe Resque::Plugins::Balancer do
  def worker(queues)
    worker = Resque::Worker.new(*queues)
    worker.fork_per_job = false # make our assertions work
    worker
  end

  let(:single_run) { 0 }

  class TestJob
    def self.queue
      'test_job'
    end

    def self.perform
      raise "Unexpected perform"
    end
  end

  class OtherJob
    def self.queue
      'other_job'
    end

    def self.perform
      raise "Unexpected perform"
    end
  end

  it "has a VERSION" do
    expect(Resque::Balancer::VERSION).to match /^[\.\da-z]+$/
  end

  it "does not blow up" do
    worker = worker(['test_job'])
    Resque.enqueue(TestJob)
    expect(TestJob).to receive(:perform)
    worker.work(single_run)
  end

  it "enqueues from the highest priority queue when everything is clean" do
    worker = worker(['other_job', 'test_job'])
    Resque.enqueue(OtherJob)
    Resque.enqueue(TestJob)
    expect(TestJob).to receive(:perform)
    expect(OtherJob).to_not receive(:perform)
    worker.work(single_run)
  end
end
