# -*- encoding : utf-8 -*-
module Dao
  class Name < ::String
    def Name.for(name)
      name.is_a?(Name) ? name : Name.new(name)
    end
  end
end
