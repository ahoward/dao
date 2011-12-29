# -*- encoding : utf-8 -*-
module Dao
  class Endpoint
    Attrs = %w( api path route block doc )
    Attrs.each{|attr| attr_accessor(attr)}

    def initialize(options = {})
      update(options)
    end

    def update(options = {})
      options.each do |key, val|
        send("#{ key }=", val)
      end
    end

    def arity
      block.arity
    end

    def call(*args)
      block.call(*args)
    end

    def to_proc
      block
    end
  end
end
