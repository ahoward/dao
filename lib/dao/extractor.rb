module Dao
  class Extractor < BlankSlate
    attr :target
    attr :extracted
    attr :strategies

    def initialize(target, *args, &block)
      @target = target
      @strategies = Map.new
      @extracted = Map.new
      extracts(*args)
    end

    def inspect
      @extracted.inspect
    end

    def extracts(*args, &block)
      hashes = []

      args.each do |arg|
        if arg.is_a?(Hash)
          hashes.push(arg)
        else
          if block
            hashes.push(arg => block)
          end
        end
      end

      hashes.each do |hash|
        hash.each do |key, val|
          next unless val.respond_to?(:call)
          @strategies[key] = val
        end
      end

      self
    end

    def method_missing(method, *args, &block)
      super unless @strategies.has_key?(method)
      extract(method, &@strategies[method])
    end

    def extract(attribute, &block)
      return @extracted[attribute] if @extracted.has_key?(attribute)

      if @target.respond_to?(attribute)
        value = @target.send(attribute)
        @extracted[attribute] = value
        return @extracted[attribute]
      end

      ivar = "@#{ attribute }"
      if @target.instance_variable_defined?(ivar)
        value = @target.instance_variable_get(ivar)
        @extracted[attribute] = value
        return @extracted[attribute]
      end

      if block
        @extracted[attribute] = block.call
        return @extracted[attribute]
      end
    end
  end
end
