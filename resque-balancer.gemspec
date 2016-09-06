name = "resque-balancer"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Resque::Balancer::VERSION do |s|
  s.summary = "Balances queues by allotted time, prevents 1 queue from starving all others."
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.required_ruby_version = '>= 2.0.0'
  s.add_runtime_dependency "resque", "~> 1.26.0"
end
