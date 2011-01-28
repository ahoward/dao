module Dao
  class Validations < ::Map
    class Callback < ::Proc
      attr :options

      def initialize(options = {}, &block)
        @options = Dao.map_for(options || {})
        super(&block)
      end

      def block
        self
      end
    end

    class << Validations
      def for(*args, &block)
        new(*args, &block)
      end

      def cast(*args)
        if args.size == 1
          value = args.first
          value.is_a?(self) ? value : self.for(value)
        else
          self.for(*args)
        end
      end
    end

    attr_accessor :result

    def initialize(*args, &block)
      @result = args.shift if args.first.is_a?(Result)
      super
    end

    def params
      result.params
    end

    def errors
      result.errors
    end

    def each(&block)
      depth_first_each(&block)
    end

    def size
      size = 0
      depth_first_each{ size += 1 }
      size
    end

    alias_method 'count', 'size'
    alias_method 'length', 'size'

    Cleared = '___CLEARED___'.freeze unless defined?(Cleared)

    def run
      previous_errors = []
      new_errors = []

      errors.each_message do |keys, message|
        previous_errors.push([keys, message])
      end

      errors.clear

      depth_first_each do |keys, callback|
        next unless callback and callback.respond_to?(:to_proc)

        value = params.get(keys)
        valid = !!callback.call(value)
        #valid = !!params.instance_exec(value, &callback)
        message = callback.options[:message] || (value.nil? ? 'is blank.' : 'is invalid.')

        unless valid
          new_errors.push([keys, message])
        else
          new_errors.push([keys, Cleared])
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

      return self
    end

    def run!
      errors.clear!
      run
    end

    NotNil = lambda{|value| !value.nil?}

    def add(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      block = args.pop if args.last.respond_to?(:call)
      block ||= NotNil
      callback = Validations::Callback.new(options, &block)
      args.push(callback)
      set(*args)
    end
  end
end
