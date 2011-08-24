class DaoGenerator < Rails::Generators::NamedBase
  source_root(File.expand_path('../templates', __FILE__))

  def copy_files
    ARGV.shift if ARGV.first == name

    case name
      when /conducer/
        generate_conducer!
      
      when /system/
        generate_system!

      when /api/
        generate_system!

      when /conducers/
        generate_system!

      when /assets/
        generate_system!

      else
        raise "dunno how to generate #{ name.inspect }"
    end
  end

protected
  def generate_conducer!
    @conducer_name = ARGV.shift.sub(/_?conducer$/i, '') + '_conducer'
    template "conducer.rb", "app/conducers/#{ @conducer_name.underscore }.rb"
  end

  def generate_system!
    dao_dir = File.join(Rails.root, 'app/dao')

    FileUtils.mkdir_p(dao_dir)
    FileUtils.mkdir_p(File.join(dao_dir, 'apis'))
    FileUtils.mkdir_p(File.join(dao_dir, 'conducers'))

    copy_file("api.rb", "app/dao/api.rb")

    copy_file("api_controller.rb", "app/controllers/api_controller.rb")
    copy_file("dao_helper.rb", "app/helpers/dao_helper.rb")

    copy_file("dao.js", "public/javascripts/dao.js")
    copy_file("dao.css", "public/stylesheets/dao.css")

    route("match 'api(/*path)' => 'api#index', :as => 'api'")

    gem("yajl-ruby")

    application(
      <<-__

        config.after_initialize do
          require 'app/dao/api.rb'
          require 'yajl/json_gem'
        end

        config.autoload_paths += %w( app/models app/dao app/dao/apis app/dao/conducers )

        ### config.action_view.javascript_expansions[:defaults] ||= []
        ### config.action_view.javascript_expansions[:defaults] += %( dao )

        ### config.action_view.stylesheet_expansions[:defaults] ||= []
        ### config.action_view.stylesheet_expansions[:defaults] += %( dao )

      __
    )
  end
end
