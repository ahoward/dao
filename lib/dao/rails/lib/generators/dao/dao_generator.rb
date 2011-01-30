class DaoGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def copy_dao_files
    copy_file("api.rb", "app/api.rb")

    copy_file("api_controller.rb", "app/controllers/api_controller.rb")

    copy_file("dao.js", "pubic/javascripts/dao.js")

    route("match 'api/*path' => 'api#call', :as => 'api'")
    route("match 'api' => 'api#index', :as => 'api_index'")

    gem("yajl-ruby")

    application(
      <<-__

        config.after_initialize do
          require 'app/api.rb'
          require 'yajl/json_gem'
        end

        config.autoload_paths += %w( app )

      __
    )
  end
end
