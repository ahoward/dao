# -*- encoding : utf-8 -*-
module Dao
  class Api
    Dao.load 'api/initializers.rb'
    Dao.load 'api/modes.rb'
    Dao.load 'api/routes.rb'
    Dao.load 'api/context.rb'
    Dao.load 'api/call.rb'
    Dao.load 'api/dsl.rb'
  end
end
