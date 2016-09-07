require "spec_helper"

SingleCov.covered! file: 'lib/resque/plugins/balancer.rb'

class InstantFeedbackLogger
  def self.formatter=(x); end
  def self.debug(_); end
  def self.info(_); end
  def self.warn(message);  raise message end
  def self.error(message); raise message; end
  def self.fatal(message); raise message; end
end

ENV["FORK_PER_JOB"] = 'false' # make assertions work

Resque.logger = InstantFeedbackLogger

# too tight loops can randomly break the usage logic since one execution might take 0.0002 and the next 0.004
RSpec::Matchers.define :with_delay_and_argument do |delay, argument|
  match { |actual| sleep delay; actual == argument }
end

describe Resque::Plugins::Balancer do
  class AllJob
    def self.perform(queue)
      raise "Unexpected perform #{queue}"
    end
  end

  class TestJob
    def self.queue
      'test_job'
    end

    def self.perform
      AllJob.perform(queue)
    end
  end

  class OtherJob
    def self.queue
      'other_job'
    end

    def self.perform
      AllJob.perform(queue)
    end
  end

  def worker(queues)
    Resque::Worker.new(*queues)
  end

  def with_env(env)
    old = env.keys.map { |k| [k, ENV[k.to_s]] }
    env.each { |k, v| ENV[k.to_s] = v }
    yield
  ensure
    old.each { |k, v| ENV[k.to_s] = v }
  end

  let(:single_run) { 0 }

  it "has a VERSION" do
    expect(Resque::Balancer::VERSION).to match /^[\.\da-z]+$/
  end

  it "does not blow up" do
    worker = worker(['test_job'])
    Resque.enqueue(TestJob)
    expect(AllJob).to receive(:perform).with('test_job')
    worker.work(single_run)
  end

  it "enqueues from the highest priority queue when everything is clean" do
    with_env 'BALANCER_WEIGHTS' => 'other_job:1,test_job:2' do
      worker = worker(['other_job', 'test_job'])
      Resque.enqueue(OtherJob)
      Resque.enqueue(TestJob)
      expect(AllJob).to receive(:perform).with('test_job').ordered
      expect(AllJob).to receive(:perform).with('other_job').ordered
      worker.work(single_run)
    end
  end

  it "treats missing weight as 1" do
    with_env 'BALANCER_WEIGHTS' => 'other_job:0.1,test_job' do
      worker = worker(['other_job', 'test_job'])
      Resque.enqueue(OtherJob)
      Resque.enqueue(TestJob)
      expect(AllJob).to receive(:perform).with('test_job').ordered
      expect(AllJob).to receive(:perform).with('other_job').ordered
      worker.work(single_run)
    end
  end

  it "enqueues by usage" do
    with_env 'BALANCER_WEIGHTS' => 'other_job:1,test_job:2' do
      worker = worker(['other_job', 'test_job'])
      Resque.enqueue(OtherJob)
      Resque.enqueue(TestJob)
      Resque.enqueue(TestJob)
      expect(AllJob).to receive(:perform).with(with_delay_and_argument(0.1, 'test_job')).ordered
      expect(AllJob).to receive(:perform).with(with_delay_and_argument(0.1, 'other_job')).ordered
      expect(AllJob).to receive(:perform).with(with_delay_and_argument(0.1, 'test_job')).ordered
      worker.work(single_run)
    end
  end

  it "frees busy queues after interval" do
    with_env 'BALANCER_RESET_INTERVAL' => '0', 'BALANCER_WEIGHTS' => 'other_job:1,test_job:2' do
      worker = worker(['other_job', 'test_job'])
      Resque.enqueue(OtherJob)
      Resque.enqueue(TestJob)
      Resque.enqueue(TestJob)
      expect(AllJob).to receive(:perform).with('test_job').ordered
      expect(AllJob).to receive(:perform).with('test_job').ordered
      expect(AllJob).to receive(:perform).with('other_job').ordered
      worker.work(single_run)
    end
  end
end
