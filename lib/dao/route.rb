# -*- encoding : utf-8 -*-
module Dao
  class Route < ::String
    Default = '/index'.freeze

    class << Route
      def default
        Default
      end

      def like?(route)
        route.to_s =~ %r{/:[^/]+}
      end

      def keys_for(route)
        route = Path.absolute_path_for(route.to_s)
        route.scan(%r{/:[^/]+}).map{|key| key.sub(%r{^/:}, '')}
      end

      def pattern_for(route)
        route = Path.absolute_path_for(route.to_s)
        re = route.gsub(%r{/:[^/]+}, '/([^/]+)')
        /#{ re }/iux
      end

      def path_for(route, params = {})
        path = Path.absolute_path_for(route.to_s)
        params = Map.new(params)
        params.each do |key, val|
          re = %r{/:#{ Regexp.escape(key.to_s) }(\Z|/)}
          repl = "/#{ val.to_s }\\1"
          path.gsub!(re, repl)
        end
        path
      end
    end

    attr_accessor :keys
    attr_accessor :pattern

    def initialize(path)
      replace(path.to_s)
      @keys = Route.keys_for(self).freeze
      @pattern = Route.pattern_for(self).freeze
      freeze
    end

    def path
      self
    end

    def path_for(params)
      Route.path_for(self, params)
    end

    def match(path)
      pattern.match(path).to_a
    end

    def params_for(path)
      match = pattern.match(path).to_a

      unless match.empty?
        map = Map.new
        _ = match.shift
        @keys.each_with_index do |key, index|
          map[key] = match[index]
        end
        map
      end
    end

    class List < ::Array
      def add(path)
        route = Route.new(path)
        push(route)
        route
      end

      def match(name)
        each do |route|
          match = route.match(name)
          return route unless match.empty?
        end
        return nil
      end
    end
  end
end
