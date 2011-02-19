## dao.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "dao" 
  spec.version = "2.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "dao"
  spec.description = "description: dao kicks the ass"

  spec.files = ["a.rb", "dao.gemspec", "db", "db/dao.yml", "lib", "lib/dao", "lib/dao/active_record.rb", "lib/dao/api", "lib/dao/api/context.rb", "lib/dao/api/dsl.rb", "lib/dao/api/initializers.rb", "lib/dao/api/interfaces.rb", "lib/dao/api/modes.rb", "lib/dao/api.rb", "lib/dao/blankslate.rb", "lib/dao/data.rb", "lib/dao/db.rb", "lib/dao/engine.rb", "lib/dao/errors.rb", "lib/dao/exceptions.rb", "lib/dao/form.rb", "lib/dao/instance_exec.rb", "lib/dao/interface.rb", "lib/dao/mode.rb", "lib/dao/mongo_mapper.rb", "lib/dao/params.rb", "lib/dao/path.rb", "lib/dao/rails", "lib/dao/rails/app", "lib/dao/rails/app/api.rb", "lib/dao/rails/app/controllers", "lib/dao/rails/app/controllers/api_controller.rb", "lib/dao/rails/engine", "lib/dao/rails/lib", "lib/dao/rails/lib/generators", "lib/dao/rails/lib/generators/dao", "lib/dao/rails/lib/generators/dao/api_generator.rb", "lib/dao/rails/lib/generators/dao/dao_generator.rb", "lib/dao/rails/lib/generators/dao/templates", "lib/dao/rails/lib/generators/dao/templates/api.rb", "lib/dao/rails/lib/generators/dao/templates/api_controller.rb", "lib/dao/rails/lib/generators/dao/templates/dao.css", "lib/dao/rails/lib/generators/dao/templates/dao.js", "lib/dao/rails/lib/generators/dao/templates/dao_helper.rb", "lib/dao/rails/lib/generators/dao/USAGE", "lib/dao/rails.rb", "lib/dao/result.rb", "lib/dao/slug.rb", "lib/dao/status.rb", "lib/dao/stdext.rb", "lib/dao/support.rb", "lib/dao/validations.rb", "lib/dao.rb", "Rakefile", "README", "sample", "test", "test/dao_test.rb", "test/helper.rb", "test/testing.rb", "test/units", "TODO"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true

  

  
    spec.add_dependency(*["tagz", "~> 8.2.0"])
  
    spec.add_dependency(*["map", "~> 2.6.1"])
  
    spec.add_dependency(*["yajl-ruby", "~> 0.7.9"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/dao"
end
