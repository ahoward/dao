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
    def cases
      @cases ||= []
    end

    def case_of?(other)
      self == other or other.cases.include?(self)
    end

    def ===(other)
      case_of?(other)
    end

    Read = %w( options get head )
    Write = %w( post put delete trace connect )
    Http = Read + Write
    Http.each do |verb|
      Mode.add(verb)
    end

    Mode.add(:read)
    Read.each{|m| Mode.read.cases.push(Mode.send(m))}

    Mode.add(:write)
    Write.each{|m| Mode.write.cases.push(Mode.send(m))}
  end
end
