require "spec_helper"

SingleCov.covered! file: 'lib/resque/plugins/balancer.rb'

describe Resque::Plugins::Balancer do
  it "has a VERSION" do
    expect(Resque::Balancer::VERSION).to match /^[\.\da-z]+$/
  end
end
