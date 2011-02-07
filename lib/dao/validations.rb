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

    def data
      result.data
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

    alias_method('count', 'size')
    alias_method('length', 'size')

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

        value = data.get(keys)
        returned = callback.call(value)

        case returned
          when Hash
            map = Dao.map(returned)
            valid = map[:valid]
            message = map[:message]

          else
            valid = !!returned
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

  module Validations::Common
    def validates_length_of(*args)
      options = Dao.options_for!(args)

      message = options[:message]

      if options[:in].is_a?(Range)
        options[:minimum] = options[:in].begin
        options[:maximum] = options[:in].end
      end
      minimum = options[:minimum] || 1
      maximum = options[:maximum]

      too_short = options[:too_short] || message || 'is too short'
      too_long = options[:too_long] || message || 'is too long'

      allow_nil = options[:allow_nil]
      allow_blank = options[:allow_blank]

      minimum = Float(minimum)
      maximum = Float(maximum) if maximum

      block =
        lambda do |value|
          map = Dao.map(:valid => true)

          if value.nil? and allow_nil
            map[:valid] = true
            break(map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            break(map)
          end

          if value.size < minimum
            map[:message] = too_short
            map[:valid] = false
            break(map)
          end

          if(maximum and(value.size > maximum))
            map[:message] = too_long
            map[:valid] = false
            break(map)
          end

          map
        end

      validates(*args, &block)
    end

    def validates_word_count_of(*args)
      options = Dao.options_for!(args)

      message = options[:message]

      if options[:in].is_a?(Range)
        options[:minimum] = options[:in].begin
        options[:maximum] = options[:in].end
      end
      minimum = options[:minimum] || 1
      maximum = options[:maximum]

      too_short = options[:too_short] || message || 'is too short'
      too_long = options[:too_long] || message || 'is too long'

      allow_nil = options[:allow_nil]
      allow_blank = options[:allow_blank]

      minimum = Float(minimum)
      maximum = Float(maximum) if maximum

      block =
        lambda do |value|
          map = Dao.map(:valid => true)

          if value.nil? and allow_nil
            map[:valid] = true
            break(map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            break(map)
          end

          words = value.split(/\s+/)

          if words.size < minimum
            map[:message] = too_short
            map[:valid] = false
            break(map)
          end

          if(maximum and(words.size > maximum))
            map[:message] = too_long
            map[:valid] = false
            break(map)
          end

          map
        end

      validates(*args, &block)
    end

    def validates_as_email(*args)
      options = Dao.options_for!(args)

      message = options[:message] || "doesn't look like an email (username@domain.com)"

      allow_nil = options[:allow_nil]
      allow_blank = options[:allow_blank]

      block =
        lambda do |value|
          map = Dao.map(:valid => true)

          if value.nil? and allow_nil
            map[:valid] = true
            break(map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            break(map)
          end

          parts = value.split(/@/)

          unless parts.size == 2
            map[:valid] = false
            break(map)
          end

          map
        end

      args.push(:message => message)
      validates(*args, &block)
    end

    def validates_as_url(*args)
      options = Dao.options_for!(args)

      message = options[:message] || "doesn't look like a url (http://domain.com)"

      allow_nil = options[:allow_nil]
      allow_blank = options[:allow_blank]

      block =
        lambda do |value|
          map = Dao.map(:valid => true)

          if value.nil? and allow_nil
            map[:valid] = true
            break(map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            break(map)
          end

          parts = value.split(%r|://|)

          unless parts.size >= 2
            map[:valid] = false
            break(map)
          end

          map
        end

      args.push(:message => message)
      validates(*args, &block)
    end

    def self.validates_as(something, message, &block)
    end

    def validates_as_phone(*args)
      options = Dao.options_for!(args)

      message = options[:message] || "doesn't look like a phone number (012.345.6789)"

      allow_nil = options[:allow_nil]
      allow_blank = options[:allow_blank]

      block =
        lambda do |value|
          map = Dao.map(:valid => true)

          if value.nil? and allow_nil
            map[:valid] = true
            break(map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            break(map)
          end

          parts = value.scan(/\d+/)

          unless parts.size >= 1
            map[:valid] = false
            break(map)
          end

          map
        end

      args.push(:message => message)
      validates(*args, &block)
    end
  end
end
