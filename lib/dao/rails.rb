if defined?(Rails)
  module Dao
    class Engine < Rails::Engine
      GEM_DIR = File.expand_path(__FILE__ + '/../../../')
      ROOT_DIR = File.join(GEM_DIR, 'lib/dao/rails')
      #APP_DIR = File.join(ROOT_DIR, 'app')

      ### https://gist.github.com/af7e572c2dc973add221

      paths.path = ROOT_DIR
      ### config.autoload_paths << APP_DIR
      ### $LOAD_PATH.push(File.join(Rails.root.to_s, 'app'))
    end
  end
end
