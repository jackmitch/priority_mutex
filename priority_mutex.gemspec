Gem::Specification.new do |s|
  s.name          = "priority_mutex"
  s.version       = File.open(File.dirname(__FILE__) + '/VERSION').read.strip
  s.licenses      = ['MIT']
  s.description   = %q{Ruby gem implementing a Mutex which allows for preemptive queuing based on priority.}
  s.summary       = %q{Ruby gem implementing a Mutex which allows for preemptive queuing based on priority.}
  s.authors       = ["Mike Jarema"]
  s.email         = %q{mike@jarema.com}
  s.files         = Dir.glob("{lib}/**/*") + %w(LICENSE README.md VERSION)
  s.homepage      = %q{http://github.com/mikejarema/priority_mutex}
  s.require_paths = ["lib"]
  s.add_runtime_dependency "rake", '~> 10'
  s.add_runtime_dependency "pqueue", '~> 2'
  s.add_development_dependency "rspec", '~> 3'
end
