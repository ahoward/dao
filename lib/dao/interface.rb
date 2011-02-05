module Dao
  class Interface
    Attrs = %w( api path method doc )
    Attrs.each{|attr| attr_accessor(attr)}

    def initialize(options = {})
      update(options)
    end

    def update(options = {})
      options.each do |key, val|
        send("#{ key }=", val)
      end
    end
  end
end
