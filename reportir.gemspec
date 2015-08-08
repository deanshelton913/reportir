# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reportir/version'

Gem::Specification.new do |spec|
  spec.name          = "reportir"
  spec.version       = Reportir::VERSION
  spec.authors       = ["Dean Shelton"]
  spec.email         = ["deanshelton913@gmail.com"]

  spec.summary       = %q{Send screenshots to s3 as a reviewable website}
  spec.description   = %q{Take screenshots with capybara/watir/whatever, and upload them automatically to an AWS S3 bucket as a static website. Requires static site configuration in S3.}
  spec.homepage      = "http://github.com/reportir"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_runtime_dependency 's3_uploader'
  spec.add_runtime_dependency 'aws-sdk'
  spec.add_runtime_dependency 'fileutils'
  spec.add_runtime_dependency 'json'
end
