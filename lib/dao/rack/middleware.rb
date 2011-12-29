# -*- encoding : utf-8 -*-
module Dao
  module Middleware 
    Dao.load %w[ rack/middleware/params_parser.rb ]
  end
end
