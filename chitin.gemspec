# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "chitin/version"

Gem::Specification.new do |s|
  s.name        = "chitin"
  s.version     = Chitin::VERSION
  s.summary     = %q{Process Exoskeleton}
  s.homepage    = %q{https://git-aws.internal.justin.tv/common/chitin-ruby}
  s.authors     = %q{Twitch}
  s.email       = %q{rhys@twitch.tv}

  s.files       = `git ls-files`.split($/)
  s.require_paths = ["lib"]

  s.add_dependency "protobuf", "~> 3.5.0"
  s.add_dependency "pg_query", "~> 0.11.0"
  s.add_dependency "activesupport"
end
