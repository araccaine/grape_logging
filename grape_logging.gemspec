# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grape_logging/version'

Gem::Specification.new do |spec|
  spec.name          = 'grape_logging'
  spec.version       = GrapeLogging::VERSION
  spec.authors       = ['aserafin']
  spec.email         = ['adrian@softmad.pl']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{Out of the box request logging for Grape!}
  spec.description   = %q{This gem provides simple request logging for Grape with just 2 lines of code you have to put in your project! In return you will get response codes, parameters, total response duration and time spent in db (if you are using ActiveRecord.)}
  spec.homepage      = 'http://github.com/aserafin/grape_logging'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'grape'

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
end