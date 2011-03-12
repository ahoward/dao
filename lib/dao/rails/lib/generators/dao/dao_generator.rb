class DaoGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def copy_api_file
    copy_file("api.rb", "app/api.rb")

    copy_file("api_controller.rb", "app/controllers/api_controller.rb")

    copy_file("dao_helper.rb", "app/helpers/dao_helper.rb")

    copy_file("dao.js", "public/javascripts/dao.js")

    copy_file("dao.css", "public/stylesheets/dao.css")

    route("match 'api(/*path)' => 'api#index', :as => 'api'")

    gem("yajl-ruby")

    application(
      <<-__

        config.after_initialize do
          require 'app/api.rb'
          require 'yajl/json_gem'
        end

        config.autoload_paths += %w( app )

        ### config.action_view.javascript_expansions[:defaults] ||= []
        ### config.action_view.javascript_expansions[:defaults] += %( dao )

        ### config.action_view.stylesheet_expansions[:defaults] ||= []
        ### config.action_view.stylesheet_expansions[:defaults] += %( dao )

      __
    )
  end
end
