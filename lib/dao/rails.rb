# -*- encoding : utf-8 -*-
if defined?(Rails)

  module Dao
  ## support unloadable
  #
    #def Api.before_remove_const
      #unload!
    #end

  ##
  #
    class Engine < Rails::Engine
      GEM_DIR = File.expand_path(__FILE__ + '/../../../')
      ROOT_DIR = File.join(GEM_DIR, 'lib/dao/rails')

      ### ref: https://gist.github.com/af7e572c2dc973add221

      paths.path = ROOT_DIR

      ### config.autoload_paths += %w( app/models app )
      ### config.autoload_paths << APP_DIR
      ### $LOAD_PATH.push(File.join(Rails.root.to_s, 'app'))

    # drop the dao parameter parser in there...
    #
      #initializer "dao.middleware" do |app|
        #app.middleware.use Dao::Middleware::ParamsParser
      #end
       
      config.after_initialize do
        Dao::Conducer.install_routes!
      end

    # yes yes, this should probably be somewhere else...
    #
      config.before_initialize do

        ActionController::Base.module_eval do
        # normalize dao params
        #
          before_action do |controller|
            Dao.current_controller ||= controller
            Dao.normalize_parameters(controller.send(:params))
          end

        # setup sane rescuing from dao errors with crap statuses
        #
        #   raise(Dao::Error::Result.new(result))
        #
          rescue_from(Dao::Error::Result) do |error|
            result = error.result
            basename = "#{ result.status.code }.html"
            error_page = File.join(Rails.root, 'public', basename)

            if test(?e, error_page)
              file = File.expand_path(error_page)
              status = result.status.code
              render(:file => file, :status => status, :layout => false)
            else
              text = result.status.to_s
              status = result.status.code
              render(:text => text, :status => status, :layout => false)
            end
          end
        end

      end

    end
  end
end
