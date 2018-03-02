# -*- encoding : utf-8 -*-
module Dao
  class Path < ::String
    class Error < ::StandardError; end
    class Error::Params < Error; end

  # class methods
  #
    class << Path
      def default
        Path.for(:dao)
      end

      def for(*args)
        new(absolute_path_for(*args))
      end

      def paths_for(arg, *args)
        path = [arg, *args].flatten.compact.join('/')
        path.gsub!(%r|[.]+/|, '/')
        path.squeeze!('/')
        path.sub!(%r|^/|, '')
        path.sub!(%r|/$|, '')
        path.split('/')
      end

      def absolute_path_for(arg, *args)
        ('/' + paths_for(arg, *args).join('/')).squeeze('/')
      end

      def params?(string)
        string.to_s =~ %r{/:[^/]+}
      end
      alias_method('=~', 'params?')

      def absolute?(string)
        string.to_s =~ %r|^\s*/|
      end

      def keys_for(path)
        path = absolute_path_for(path)
        path.scan(%r{/:[^/]+}).map{|key| key.sub(%r{^/:}, '')}
      end

      def expand!(path, params = {})
        params = Map.for(params)
        path.keys.each do |key|
          path.gsub!(%r{/:#{ Regexp.escape(key) }\b}, params[key])
        end
        path
      end

      def pattern_for(path)
        path = absolute_path_for(path)
        re = path.gsub(%r{/:[^/]+}, '/([^/]+)')
        /^#{ re }$/i
      end

      def extract_params(enumerable, keys)
        params = Map.new
        keys = Array(keys)
        case enumerable
          when Array
            keys.each_with_index{|key, index| params[key] = enumerable[index]}
          when Hash
            enumerable = Map.for(enumerable)
            keys.each{|key| params[key] = enumerable[key]}
          else
            raise(ArgumentError, enumerable.class.name)
        end
        params
      end
    end

    attr_accessor :result
    attr_accessor :keys
    attr_accessor :pattern
    attr_accessor :params
    attr_accessor :interface

    def initialize(*args, &block)
      super(args.join('/'), &block)
      normalize!
      compile!
    end

    def params?
      Path.params?(self)
    end

    def normalize!
      replace(Path.absolute_path_for(self))
    end

    def compile!
      @keys = Path.keys_for(self)
      @pattern = Path.pattern_for(self)
      @params = Map.new
      @path = dup
    end

    def expand(params)
      dup.expand!(params)
    end

    class ParamsError < ::StandardError; end

    def expand!(params)
      replace(@path.dup)
      @params = extract_params(params)
      keys.each do |key|
        next if @params[key].nil?
        re = %r{/:#{ Regexp.escape(key) }\b}
        val = "/#{ @params[key] }"
        self.gsub!(re, val)
      end
      raise(Error::Params, "#{ self }(#{ @params.inspect })") if params?
      self
    end

    def absolute?
      Path.absolute?(self)
    end

    def match(other)
      matched, *matches = @pattern.match(other).to_a
      matched ? expand(matches) : false
    end

    def match!(other)
      matched, *matches = @pattern.match(other).to_a
      matched ? expand!(matches) : false
    end

    def extract_params(enumerable)
      Path.extract_params(enumerable, @keys)
    end

    def +(other)
      Path.for(super)
    end

    def to_yaml(*args, &block)
      "#{ self }".to_yaml(*args, &block)
    end
  end
end
