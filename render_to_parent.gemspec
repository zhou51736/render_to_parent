# -*- encoding: utf-8 -*-
require File.expand_path('../lib/render_to_parent/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["zb"]
  gem.email         = ["zhou51736@gmail.com"]
  gem.description   = %q{rails 3.2 for respond to parent}
  gem.summary       = %q{render_to_parent}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "render_to_parent"
  gem.require_paths = ["lib"]
  gem.version       = RenderToParent::VERSION
end
