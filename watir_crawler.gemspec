# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'watir_crawler/version'

Gem::Specification.new do |spec|
  spec.name          = 'watir_crawler'
  spec.version       = WatirCrawler::VERSION
  spec.authors       = ['Dmitry T']
  spec.email         = ['atlancer@gmail.com']
  spec.description   = %q{A watir based web crawler}
  spec.summary       = %q{A watir based web crawler}
  spec.homepage      = ''
  spec.license       = 'MIT'
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_dependency 'nestegg'
  spec.add_dependency 'settingslogic'
  spec.add_dependency 'watir-webdriver', '~> 0.6.4'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 2.6'
  spec.add_development_dependency 'rake'
end
