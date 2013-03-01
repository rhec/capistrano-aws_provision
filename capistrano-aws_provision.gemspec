# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/aws_provision/version'

Gem::Specification.new do |gem|
  gem.name          = "capistrano-aws_provision"
  gem.version       = Capistrano::AwsProvision::VERSION
  gem.authors       = ["Rob Eanes"]
  gem.email         = ["reanes@gmail.com"]
  gem.description   = %q{Capistrano tasks for provisioning servers on AWS}
  gem.summary       = gem.description
  gem.homepage      = "http://github.com/rhec/capistrano-aws_provision"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency 'capistrano'
  gem.add_runtime_dependency 'fog'
  gem.add_runtime_dependency 'hashie'

end
