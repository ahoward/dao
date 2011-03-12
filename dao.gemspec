## dao.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "dao" 
  spec.version = "2.2.1"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "dao"
  spec.description = "description: dao kicks the ass"

  spec.files = ["a.rb", "dao.gemspec", "lib", "lib/dao", "lib/dao/active_record.rb", "lib/dao/api", "lib/dao/api/context.rb", "lib/dao/api/dsl.rb", "lib/dao/api/endpoints.rb", "lib/dao/api/initializers.rb", "lib/dao/api/interfaces.rb", "lib/dao/api/modes.rb", "lib/dao/api.rb", "lib/dao/blankslate.rb", "lib/dao/data.rb", "lib/dao/db.rb", "lib/dao/endpoint.rb", "lib/dao/engine.rb", "lib/dao/errors.rb", "lib/dao/exceptions.rb", "lib/dao/form.rb", "lib/dao/instance_exec.rb", "lib/dao/interface.rb", "lib/dao/mode.rb", "lib/dao/mongo_mapper.rb", "lib/dao/params.rb", "lib/dao/path.rb", "lib/dao/rails", "lib/dao/rails/app", "lib/dao/rails/app/api.rb", "lib/dao/rails/app/controllers", "lib/dao/rails/app/controllers/api_controller.rb", "lib/dao/rails/lib", "lib/dao/rails/lib/generators", "lib/dao/rails/lib/generators/dao", "lib/dao/rails/lib/generators/dao/api_generator.rb", "lib/dao/rails/lib/generators/dao/dao_generator.rb", "lib/dao/rails/lib/generators/dao/templates", "lib/dao/rails/lib/generators/dao/templates/api.rb", "lib/dao/rails/lib/generators/dao/templates/api_controller.rb", "lib/dao/rails/lib/generators/dao/templates/dao.css", "lib/dao/rails/lib/generators/dao/templates/dao.js", "lib/dao/rails/lib/generators/dao/templates/dao_helper.rb", "lib/dao/rails/lib/generators/dao/USAGE", "lib/dao/rails.rb", "lib/dao/result.rb", "lib/dao/slug.rb", "lib/dao/status.rb", "lib/dao/stdext.rb", "lib/dao/support.rb", "lib/dao/validations.rb", "lib/dao.rb", "Rakefile", "README", "sample", "sample/rails_app", "sample/rails_app/app", "sample/rails_app/app/api.rb", "sample/rails_app/app/controllers", "sample/rails_app/app/controllers/api_controller.rb", "sample/rails_app/app/controllers/application_controller.rb", "sample/rails_app/app/helpers", "sample/rails_app/app/helpers/application_helper.rb", "sample/rails_app/app/mailers", "sample/rails_app/app/models", "sample/rails_app/app/views", "sample/rails_app/app/views/layouts", "sample/rails_app/app/views/layouts/application.html.erb", "sample/rails_app/config", "sample/rails_app/config/application.rb", "sample/rails_app/config/boot.rb", "sample/rails_app/config/database.yml", "sample/rails_app/config/environment.rb", "sample/rails_app/config/environments", "sample/rails_app/config/environments/development.rb", "sample/rails_app/config/environments/production.rb", "sample/rails_app/config/environments/test.rb", "sample/rails_app/config/initializers", "sample/rails_app/config/initializers/backtrace_silencers.rb", "sample/rails_app/config/initializers/inflections.rb", "sample/rails_app/config/initializers/mime_types.rb", "sample/rails_app/config/initializers/secret_token.rb", "sample/rails_app/config/initializers/session_store.rb", "sample/rails_app/config/locales", "sample/rails_app/config/locales/en.yml", "sample/rails_app/config/routes.rb", "sample/rails_app/config.ru", "sample/rails_app/db", "sample/rails_app/db/development.sqlite3", "sample/rails_app/db/seeds.rb", "sample/rails_app/doc", "sample/rails_app/doc/README_FOR_APP", "sample/rails_app/Gemfile", "sample/rails_app/Gemfile.lock", "sample/rails_app/lib", "sample/rails_app/lib/tasks", "sample/rails_app/log", "sample/rails_app/log/development.log", "sample/rails_app/log/production.log", "sample/rails_app/log/server.log", "sample/rails_app/log/test.log", "sample/rails_app/pubic", "sample/rails_app/pubic/javascripts", "sample/rails_app/pubic/javascripts/dao.js", "sample/rails_app/public", "sample/rails_app/public/404.html", "sample/rails_app/public/422.html", "sample/rails_app/public/500.html", "sample/rails_app/public/favicon.ico", "sample/rails_app/public/images", "sample/rails_app/public/images/rails.png", "sample/rails_app/public/index.html", "sample/rails_app/public/javascripts", "sample/rails_app/public/javascripts/application.js", "sample/rails_app/public/javascripts/controls.js", "sample/rails_app/public/javascripts/dragdrop.js", "sample/rails_app/public/javascripts/effects.js", "sample/rails_app/public/javascripts/prototype.js", "sample/rails_app/public/javascripts/rails.js", "sample/rails_app/public/robots.txt", "sample/rails_app/public/stylesheets", "sample/rails_app/Rakefile", "sample/rails_app/README", "sample/rails_app/script", "sample/rails_app/script/rails", "sample/rails_app/test", "sample/rails_app/test/fixtures", "sample/rails_app/test/functional", "sample/rails_app/test/integration", "sample/rails_app/test/performance", "sample/rails_app/test/performance/browsing_test.rb", "sample/rails_app/test/test_helper.rb", "sample/rails_app/test/unit", "sample/rails_app/tmp/cache", "sample/rails_app/tmp/pids", "sample/rails_app/tmp/sessions", "sample/rails_app/tmp/sockets", "sample/rails_app/vendor", "sample/rails_app/vendor/plugins", "test", "test/dao_test.rb", "test/helper.rb", "test/testing.rb", "test/units", "TODO"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true

  

  
    spec.add_dependency(*["tagz", "~> 8.2.0"])
  
    spec.add_dependency(*["map", "~> 2.7.0"])
  
    spec.add_dependency(*["yajl-ruby", "~> 0.7.9"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/dao"
end
