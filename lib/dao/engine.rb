module Dao
  if(defined?(Rails) && Rails::VERSION::MAJOR == 3)
    class Engine < Rails::Engine
      engine_name :dao
    end
  end
end
