# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "google_contacts/version"

Gem::Specification.new do |s|
  s.name        = "googlecontacts"
  s.version     = GoogleContacts::VERSION
  s.authors     = ["Pieter Noordhuis"]
  s.email       = ["pcnoordhuis@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Google Contacts API implementation}

  s.rubyforge_project = "googlecontacts"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activesupport", ">= 2.3.4"
  s.add_runtime_dependency "nokogiri", ">= 1.4.1"
  s.add_runtime_dependency "oauth", ">= 0.3.6"
end
