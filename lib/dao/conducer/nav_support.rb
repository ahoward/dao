# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    def nav_for(name, &block)
      Nav.new(name, &block).for(controller)
    end
    alias_method(:nav, :nav_for)
  end
end
