require File.expand_path("../lib/omniauth-promise/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "omniauth-promise"
  spec.authors       = ["Anders Lemke-Holstein"]
  spec.email         = ["anders@lemke.dk"]

  spec.summary       = %q{Add Promise}
  spec.homepage      = "https://promiseauthentication.org"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.add_dependency "omniauth", "~> 1.0"
  spec.add_dependency "json-jwt", "~> 1.0"
  spec.add_dependency "faraday-http-cache", "~> 2.0"
  spec.add_dependency "multi_json", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "json-jwt", "~> 1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://promiseauthentication.org"
  spec.metadata["changelog_uri"] = "https://promiseauthentication.org"

  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.name          = "omniauth-promise"
  spec.require_paths = ["lib"]
  spec.version       = OmniAuth::Promise::VERSION
end
