## dao.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "dao"
  spec.version = "2.0.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "dao"
  spec.description = "description: dao kicks the ass"

  spec.files = ["dao.gemspec", "db", "db/dao.yml", "lib", "lib/dao", "lib/dao/active_record.rb", "lib/dao/api", "lib/dao/api/context.rb", "lib/dao/api/dsl.rb", "lib/dao/api/endpoints.rb", "lib/dao/api/initializers.rb", "lib/dao/api/modes.rb", "lib/dao/api.rb", "lib/dao/blankslate.rb", "lib/dao/data.rb", "lib/dao/db.rb", "lib/dao/endpoint.rb", "lib/dao/engine.rb", "lib/dao/errors.rb", "lib/dao/exceptions.rb", "lib/dao/form.rb", "lib/dao/mode.rb", "lib/dao/mongo_mapper.rb", "lib/dao/params.rb", "lib/dao/path.rb", "lib/dao/rails", "lib/dao/rails/app", "lib/dao/rails/app/api.rb", "lib/dao/rails/app/controllers", "lib/dao/rails/app/controllers/api_controller.rb", "lib/dao/rails/engine", "lib/dao/rails/lib", "lib/dao/rails/lib/generators", "lib/dao/rails/lib/generators/dao", "lib/dao/rails/lib/generators/dao/api_generator.rb", "lib/dao/rails/lib/generators/dao/dao_generator.rb", "lib/dao/rails/lib/generators/dao/templates", "lib/dao/rails/lib/generators/dao/templates/api.rb", "lib/dao/rails/lib/generators/dao/templates/api_controller.rb", "lib/dao/rails/lib/generators/dao/USAGE", "lib/dao/rails.rb", "lib/dao/result.rb", "lib/dao/slug.rb", "lib/dao/status.rb", "lib/dao/stdext.rb", "lib/dao/support.rb", "lib/dao/validations.rb", "lib/dao.rb", "rails_app", "rails_app/app", "rails_app/app/api.rb", "rails_app/app/controllers", "rails_app/app/controllers/api_controller.rb", "rails_app/app/controllers/application_controller.rb", "rails_app/app/helpers", "rails_app/app/helpers/application_helper.rb", "rails_app/app/mailers", "rails_app/app/models", "rails_app/app/views", "rails_app/app/views/layouts", "rails_app/app/views/layouts/application.html.erb", "rails_app/config", "rails_app/config/application.rb", "rails_app/config/boot.rb", "rails_app/config/database.yml", "rails_app/config/environment.rb", "rails_app/config/environments", "rails_app/config/environments/development.rb", "rails_app/config/environments/production.rb", "rails_app/config/environments/test.rb", "rails_app/config/initializers", "rails_app/config/initializers/backtrace_silencers.rb", "rails_app/config/initializers/inflections.rb", "rails_app/config/initializers/mime_types.rb", "rails_app/config/initializers/secret_token.rb", "rails_app/config/initializers/session_store.rb", "rails_app/config/locales", "rails_app/config/locales/en.yml", "rails_app/config/routes.rb", "rails_app/config.ru", "rails_app/db", "rails_app/db/development.sqlite3", "rails_app/db/seeds.rb", "rails_app/doc", "rails_app/doc/README_FOR_APP", "rails_app/Gemfile", "rails_app/Gemfile.lock", "rails_app/lib", "rails_app/lib/tasks", "rails_app/log", "rails_app/log/development.log", "rails_app/log/production.log", "rails_app/log/server.log", "rails_app/log/test.log", "rails_app/public", "rails_app/public/404.html", "rails_app/public/422.html", "rails_app/public/500.html", "rails_app/public/favicon.ico", "rails_app/public/images", "rails_app/public/images/rails.png", "rails_app/public/index.html", "rails_app/public/javascripts", "rails_app/public/javascripts/application.js", "rails_app/public/javascripts/controls.js", "rails_app/public/javascripts/dragdrop.js", "rails_app/public/javascripts/effects.js", "rails_app/public/javascripts/prototype.js", "rails_app/public/javascripts/rails.js", "rails_app/public/robots.txt", "rails_app/public/stylesheets", "rails_app/Rakefile", "rails_app/README", "rails_app/script", "rails_app/script/rails", "rails_app/test", "rails_app/test/fixtures", "rails_app/test/functional", "rails_app/test/integration", "rails_app/test/performance", "rails_app/test/performance/browsing_test.rb", "rails_app/test/test_helper.rb", "rails_app/test/unit", "rails_app/tmp/cache", "rails_app/tmp/pids", "rails_app/tmp/sessions", "rails_app/tmp/sockets", "rails_app/vendor", "rails_app/vendor/plugins", "Rakefile", "README", "test", "test/dao_test.rb", "test/helper.rb", "test/testing.rb", "test/units", "TODO"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true
  spec.test_files = nil

# spec.add_dependency 'lib', '>= version'
  spec.add_dependency 'map'
  spec.add_dependency 'tagz'
  spec.add_dependency 'yajl-ruby'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/dao"
end
