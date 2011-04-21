## dao.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "dao" 
  spec.version = "3.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "dao"
  spec.description = "description: dao kicks the ass"

  spec.files = ["dao.gemspec", "lib", "lib/dao", "lib/dao/active_record.rb", "lib/dao/api", "lib/dao/api/context.rb", "lib/dao/api/dsl.rb", "lib/dao/api/endpoints.rb", "lib/dao/api/initializers.rb", "lib/dao/api/interfaces.rb", "lib/dao/api/modes.rb", "lib/dao/api.rb", "lib/dao/blankslate.rb", "lib/dao/data.rb", "lib/dao/db.rb", "lib/dao/endpoint.rb", "lib/dao/engine.rb", "lib/dao/errors.rb", "lib/dao/exceptions.rb", "lib/dao/form.rb", "lib/dao/instance_exec.rb", "lib/dao/interface.rb", "lib/dao/mode.rb", "lib/dao/mongo_mapper.rb", "lib/dao/params.rb", "lib/dao/path.rb", "lib/dao/presenter.rb", "lib/dao/rails", "lib/dao/rails/lib", "lib/dao/rails/lib/generators", "lib/dao/rails/lib/generators/dao", "lib/dao/rails/lib/generators/dao/api_generator.rb", "lib/dao/rails/lib/generators/dao/dao_generator.rb", "lib/dao/rails/lib/generators/dao/templates", "lib/dao/rails/lib/generators/dao/templates/api.rb", "lib/dao/rails/lib/generators/dao/templates/api_controller.rb", "lib/dao/rails/lib/generators/dao/templates/dao.css", "lib/dao/rails/lib/generators/dao/templates/dao.js", "lib/dao/rails/lib/generators/dao/templates/dao_helper.rb", "lib/dao/rails/lib/generators/dao/USAGE", "lib/dao/rails.rb", "lib/dao/result.rb", "lib/dao/slug.rb", "lib/dao/status.rb", "lib/dao/stdext.rb", "lib/dao/support.rb", "lib/dao/validations", "lib/dao/validations/base.rb", "lib/dao/validations/common.rb", "lib/dao/validations.rb", "lib/dao.rb", "Rakefile", "README", "test", "test/dao_test.rb", "test/helper.rb", "test/testing.rb", "test/units", "TODO"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true

  

  
    spec.add_dependency(*["tagz", "~> 8.2.0"])
  
    spec.add_dependency(*["map", "~> 2.9.1"])
  
    spec.add_dependency(*["yajl-ruby", "~> 0.8.1"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/dao"
end
