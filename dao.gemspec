## dao.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "dao"
  spec.version = "6.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "dao"
  spec.description = "presenter, conducer, api, and better form objects for you rails' pleasure"
  spec.license = "same as ruby's"

  spec.files =
["Gemfile",
 "Gemfile.lock",
 "README",
 "Rakefile",
 "dao.gemspec",
 "lib",
 "lib/dao",
 "lib/dao.rb",
 "lib/dao/active_record.rb",
 "lib/dao/api",
 "lib/dao/api.rb",
 "lib/dao/api/call.rb",
 "lib/dao/api/context.rb",
 "lib/dao/api/dsl.rb",
 "lib/dao/api/initializers.rb",
 "lib/dao/api/modes.rb",
 "lib/dao/api/routes.rb",
 "lib/dao/blankslate.rb",
 "lib/dao/conducer",
 "lib/dao/conducer.rb",
 "lib/dao/conducer/active_model.rb",
 "lib/dao/conducer/attributes.rb",
 "lib/dao/conducer/autocrud.rb",
 "lib/dao/conducer/callback_support.rb",
 "lib/dao/conducer/collection.rb",
 "lib/dao/conducer/controller_support.rb",
 "lib/dao/conducer/view_support.rb",
 "lib/dao/data.rb",
 "lib/dao/db.rb",
 "lib/dao/endpoint.rb",
 "lib/dao/engine.rb",
 "lib/dao/errors.rb",
 "lib/dao/exceptions.rb",
 "lib/dao/extractor.rb",
 "lib/dao/form.rb",
 "lib/dao/instance_exec.rb",
 "lib/dao/messages.rb",
 "lib/dao/mode.rb",
 "lib/dao/mongo_mapper.rb",
 "lib/dao/name.rb",
 "lib/dao/params.rb",
 "lib/dao/path.rb",
 "lib/dao/path_map.rb",
 "lib/dao/rack",
 "lib/dao/rack.rb",
 "lib/dao/rack/middleware",
 "lib/dao/rack/middleware.rb",
 "lib/dao/rack/middleware/params_parser.rb",
 "lib/dao/rails",
 "lib/dao/rails.rb",
 "lib/dao/rails/lib",
 "lib/dao/rails/lib/generators",
 "lib/dao/rails/lib/generators/dao",
 "lib/dao/rails/lib/generators/dao/USAGE",
 "lib/dao/rails/lib/generators/dao/dao_generator.rb",
 "lib/dao/rails/lib/generators/dao/templates",
 "lib/dao/rails/lib/generators/dao/templates/api.rb",
 "lib/dao/rails/lib/generators/dao/templates/api_controller.rb",
 "lib/dao/rails/lib/generators/dao/templates/conducer.rb",
 "lib/dao/rails/lib/generators/dao/templates/dao.css",
 "lib/dao/rails/lib/generators/dao/templates/dao.js",
 "lib/dao/rails/lib/generators/dao/templates/dao_helper.rb",
 "lib/dao/result.rb",
 "lib/dao/route.rb",
 "lib/dao/slug.rb",
 "lib/dao/status.rb",
 "lib/dao/stdext.rb",
 "lib/dao/support.rb",
 "lib/dao/upload.rb",
 "lib/dao/validations",
 "lib/dao/validations.rb",
 "lib/dao/validations/callback.rb",
 "lib/dao/validations/common.rb",
 "lib/dao/validations/instance.rb",
 "lib/dao/validations/validator.rb",
 "test",
 "test/active_model_conducer_lint_test.rb",
 "test/api_test.rb",
 "test/conducer_test.rb",
 "test/data",
 "test/data/han-solo.jpg",
 "test/errors_test.rb",
 "test/form_test.rb",
 "test/helper.rb",
 "test/leak.rb",
 "test/support_test.rb",
 "test/testing.rb",
 "test/validations_test.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["rails", " ~> 5.1.0.rc1"])
  
    spec.add_dependency(*["map", " >= 6.0.0"])
  
    spec.add_dependency(*["fattr", " >= 2.2"])
  
    spec.add_dependency(*["coerce", " >= 0.0.3"])
  
    spec.add_dependency(*["tagz", " >= 9.9.2"])
  
    spec.add_dependency(*["multi_json", " >= 1.0.3"])
  
    spec.add_dependency(*["uuidtools", " >= 2.1.2"])
  
    spec.add_dependency(*["wrap", " >= 1.5.0"])
  
    spec.add_dependency(*["rails_current", " >= 1.8.0"])
  
    spec.add_dependency(*["rails_errors2html", " >= 1.3.0"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/dao"
end
