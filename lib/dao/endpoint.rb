# -*- encoding : utf-8 -*-
module Dao
  class Endpoint
    Attrs = %w( api path route block doc )
    Attrs.each{|attr| fattr(attr)}

    def initialize(options = {})
      @helpers = Module.new{ extend self }
      update(options)
    end

    def update(options = {})
      options.each do |key, val|
        send("#{ key }=", val)
      end
    end

    def arity
      @block.arity if @block
    end

    def call(*args, &block)
      if block
        @block = block
      else
        @block.call(*args) if @block
      end
    end

    def to_proc
      @block if @block
    end

    def helpers(&block)
      if block
        @helpers.module_eval(&block)
      else
        @helpers
      end
    end

    alias_method :h, :helpers
  end
end
