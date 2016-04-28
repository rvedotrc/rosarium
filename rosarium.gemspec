# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'rosarium'
  s.version     = '0.1.0'
  s.summary     = 'Promises, or something like them'
  s.description = <<-EOF
    Rosarium implements something that's a bit like Promises,
    inspired by the stability and ease of use of Q
    (<https://github.com/kriskowal/q/wiki/API-Reference>).
  EOF
  s.homepage    = 'http://rve.org.uk/gems/rosarium'
  s.authors     = ['Rachel Evans']
  s.email       = 'git@rve.org.uk'
  s.license     = 'Apache-2.0'
  s.require_paths = ["lib"]

  s.files       = Dir.glob(%w[
LICENSE
README.md
Gemfile
Gemfile.lock
bin/*
lib/**/*.rb
spec/*.rb
  ])

  # NOTE: if you change these dependencies, also change the Gemfile
  s.add_development_dependency 'rspec', "~> 3.4"
end
