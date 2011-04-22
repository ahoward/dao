module Dao
  class Validations < ::Map
  # supporting classes
  #
    class Callback < ::Proc
      attr :options

      def initialize(options = {}, &block)
        @options = Dao.map_for(options || {})
        super(&block)
      end

      def block
        self
      end

      class Chain
        def initialize
          @chain = []
        end

        def add(callback)
          @chain.push(callback)
        end

        def each(&block)
          @chain.each(&block)
        end
      end
    end

  # class methods
  #
    class << Validations
      def for(*args, &block)
        new(*args, &block)
      end
    end

  # instance methods
  #
    attr_accessor :map
    attr_accessor :errors
    attr_accessor :status
    attr_accessor :ran

    def initialize(*args, &block)
      @map = args.first.is_a?(Map) ? args.shift : Map.new
      options = Map.options_for!(args)

      @errors = options[:errors] || Errors.new
      @status = options[:status] || Status.default

      @map.extend(InstanceExec) unless @map.respond_to?(:instance_exec)
      @ran = false
      super
    end
    alias_method('ran?', 'ran')

    def errors
      @map.errors
    end

    def run
      previous_errors = []
      new_errors = []

      errors.each_message do |keys, message|
        previous_errors.push([keys, message])
      end
      errors.clear!

      depth_first_each do |keys, chain|
        chain.each do |callback|
          next unless callback and callback.respond_to?(:to_proc)

          number_of_errors = errors.size
          value = @map.get(keys)
          returned =
            catch(:valid) do
              args = [value, map].slice(0, callback.arity)
              @map.instance_exec(*args, &callback)
            end

          case returned
            when Hash
              map = Dao.map(returned)
              valid = map[:valid]
              message = map[:message]

            when TrueClass, FalseClass
              valid = returned
              message = nil

            else
              any_errors_added = errors.size > number_of_errors
              valid = !any_errors_added
              message = nil
          end

          message ||= callback.options[:message]
          message ||= (value.to_s.strip.empty? ? 'is blank' : 'is invalid')

          unless valid
            new_errors.push([keys, message])
          else
            new_errors.push([keys, Cleared])
          end
        end
      end

      previous_errors.each do |keys, message|
        errors.add(keys, message) unless new_errors.assoc(keys)
      end

      new_errors.each do |keys, value|
        next if value == Cleared
        message = value
        errors.add(keys, message)
      end

      @ran = true
      return self
    end
    Cleared = 'Cleared'.freeze unless defined?(Cleared)

    def run!
      errors.clear!
      run
    end

    def each(&block)
      depth_first_each(&block)
    end

    def size
      size = 0
      depth_first_each{ size += 1 }
      size
    end
    alias_method('count', 'size')
    alias_method('length', 'size')

    def add(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      block = args.pop if args.last.respond_to?(:call)
      block ||= NotNil
      callback = Callback.new(options, &block)
      set(args => Callback::Chain.new) unless has?(args)
      get(args).add(callback)
      callback
    end
    NotNil = lambda{|value| !value.nil?} unless defined?(NotNil)
  end

  Dao.load('validations/base.rb')
  Dao.load('validations/common.rb')

  module Validations::Mixin
    def self.included(other)
      other.module_eval do
        include Validations::Base
        include Validations::Common 
      end
      super
    end

    def self.list
      @list ||= (
        c = Class.new
        a = c.instance_methods
        c.class_eval{ include Validations::Mixin }
        b = c.instance_methods
        b - a
      )
    end
  end
end
