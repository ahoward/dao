# vim: syntax=ruby
load 'tasks/this.rb'

This.name     = "dao"
This.author   = "Ara T. Howard"
This.email    = "ara.t.howard@gmail.com"
This.homepage = "https://github.com/ahoward/#{ This.name }"

This.ruby_gemspec do |spec|
  spec.add_dependency( "map",               "~> 6.0")
  spec.add_dependency( "rails",             "~> 5.1.0")
  spec.add_dependency( "fattr",             "~> 2.2")
  spec.add_dependency( "coerce",            ">= 0.0.3")
  spec.add_dependency( "tagz",              "~> 9.9")
  spec.add_dependency( "multi_json",        ">= 1.0.3")
  spec.add_dependency( "uuidtools",         ">= 2.1.2")
  spec.add_dependency( "wrap",              ">= 1.5.0")
  spec.add_dependency( "rails_current",     ">= 2.0.0")
  spec.add_dependency( "rails_errors2html", ">= 1.3.0" )

  spec.add_development_dependency( 'rake'     , '~> 12.1')
  spec.add_development_dependency( 'minitest' , '~> 5.0' )

  spec.licenses = ['Ruby']
end

load 'tasks/default.rake'
