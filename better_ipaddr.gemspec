# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'better_ipaddr/version'

Gem::Specification.new do |spec|
  spec.name          = "better_ipaddr"
  spec.version       = BetterIpaddr::VERSION
  spec.authors       = ["Ben Miller"]
  spec.email         = ["bmiller@rackspace.com"]

  spec.summary       = "IPAddr enhancements for network management."
  spec.homepage      = "https://github.com/bjmllr/better_ipaddr"
  spec.license       = "GPL-3.0"

  spec.files         = `git ls-files -z`.split("\x0")
                       .reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r(^exe/)) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
