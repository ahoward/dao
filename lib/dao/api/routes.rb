# -*- encoding : utf-8 -*-
module Dao
  class Api
    class << Api
      def routes
        @routes ||= Route::List.new
      end
    end
  end
end
