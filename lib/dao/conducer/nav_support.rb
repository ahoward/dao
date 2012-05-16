# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    def nav_for(*args, &block)
      Nav.new(*args, &block).for(controller)
    end
    alias_method(:nav, :nav_for)
    alias_method(:navigation, :nav_for)
    alias_method(:navigation_for, :nav_for)
  end
end
