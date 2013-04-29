# -*- encoding : utf-8 -*-
module Dao
  class Mode < ::String
  # class methods
  #
    class << Mode
      def for(mode)
        return mode if mode.is_a?(Mode)
        mode = mode.to_s
        return Mode.send(mode) if Mode.respond_to?(mode)
        Mode.new(mode)
      end

      def list
        @list ||= []
      end

      def add(mode)
        mode = new(mode.to_s)

        unless list.include?(mode)
          list.push(mode)
          singleton_class =
            class << Mode
              self
            end
          singleton_class.module_eval do
            attr_accessor mode
          end
          Mode.send("#{ mode }=", mode)
          mode
        end
      end

      def default
        @default ||= Mode.for(:read)
      end
    end

  # instance methods
  #
    def aliases
      @aliases ||= []
    end

    def Mode.alias(a, b)
      a, b = Mode.for(a), Mode.for(b)
      a.aliases.push(b) unless a.aliases.include?(b)
      b.aliases.push(a) unless b.aliases.include?(a)
      (a.aliases + b.aliases).uniq
    end

    def case_of?(other)
      a, b = self, Mode.for(other)
      a == b or a.aliases.include?(b) or b.aliases.include?(a)
    end

    def ===(other)
      case_of?(other)
    end

  # setup mode singletons and their aliases
  #
    HTTP = ( READ = %w[ get options head ] ) + ( WRITE = %w[ post put delete trace connect ] )

    Mode.add(:read)
    Mode.add(:write)

    HTTP.each{|verb| Mode.add(verb)}

    Mode.alias(:read, :get)
    Mode.alias(:write, :post)
  end
end
