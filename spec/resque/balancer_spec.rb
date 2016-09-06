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
    worker = Resque::Worker.new(*queues)
    worker.fork_per_job = false # make our assertions work
    worker
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
    with_env 'WEIGHTS' => 'other_job:2' do
      worker = worker(['test_job'])
      Resque.enqueue(TestJob)
      expect(AllJob).to receive(:perform).with('test_job')
      worker.work(single_run)
    end
  end

  it "fails with missing WEIGHTS" do
    expect do
      worker(['test_job']).work(single_run)
    end.to raise_error(/WEIGHTS/)
  end

  it "enqueues from the highest priority queue when everything is clean" do
    with_env 'WEIGHTS' => 'other_job:1,test_job:2' do
      worker = worker(['other_job', 'test_job'])
      Resque.enqueue(OtherJob)
      Resque.enqueue(TestJob)
      expect(AllJob).to receive(:perform).with('test_job').ordered
      expect(AllJob).to receive(:perform).with('other_job').ordered
      worker.work(single_run)
    end
  end
end
