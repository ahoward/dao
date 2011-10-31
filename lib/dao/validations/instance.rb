module Dao
  module Validations
    class Instance < ::Map
    end

    Instance.send(:include, Validations)

    def Validations.new(*args, &block)
      Instance.new(*args, &block)
    end

    def Validations.for(*args, &block)
      Instance.new(*args, &block)
    end
  end
end
