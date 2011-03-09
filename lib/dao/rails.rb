if defined?(Rails)
  module Dao
    class Engine < Rails::Engine
      GEM_DIR = File.expand_path(__FILE__ + '/../../../')
      ROOT_DIR = File.join(GEM_DIR, 'lib/dao/rails')

      ### ref: https://gist.github.com/af7e572c2dc973add221

      paths.path = ROOT_DIR

      ### config.autoload_paths << APP_DIR
      ### $LOAD_PATH.push(File.join(Rails.root.to_s, 'app'))
      #config.after_initialize do
        #unloadable(Dao)
      #end
       
      config.after_initialize do

        ActionController::Base.module_eval do

        # you will likely want to override this!
        #
          def api
            @api ||= ::Api.new(current_user) rescue nil
          end

        # setup sane rescuing from dao errors with bad statuses
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
