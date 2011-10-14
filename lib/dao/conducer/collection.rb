module Dao
  class Conducer
    class Collection < ::Array
      Fattr(:conducer_class){ Dao::Conducer }

      fattr(:attributes){ Map.new }
      alias_method(:data, :attributes)

      module_eval(&ViewSupport)
    end
  end
end
