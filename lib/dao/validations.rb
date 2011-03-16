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
    attr_accessor :ran

    def initialize(*args, &block)
      @result = args.shift if args.first.is_a?(Result)
      @ran = false
      super
    end

    alias_method('ran?', 'ran')

    def params
      result.params
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

      depth_first_each do |keys, chain|
        chain.each do |callback|
          next unless callback and callback.respond_to?(:to_proc)

          number_of_errors = errors.size
          value = data.get(keys)
          returned =
            catch(:valid) do
              if result
                result.instance_exec(value, &callback)
              else
                callback.call(value)
              end
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
      set(args => Callback::Chain.new) unless has?(args)
      get(args).add(callback)
      callback
      #args.push(callback)
      #set(*args)
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
            throw(:valid, map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            throw(:valid, map)
          end

          if value.size < minimum
            map[:message] = too_short
            map[:valid] = false
            throw(:valid, map)
          end

          if(maximum and(value.size > maximum))
            map[:message] = too_long
            map[:valid] = false
            throw(:valid, map)
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
            throw(:valid, map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            throw(:valid, map)
          end

          words = value.split(/\s+/)

          if words.size < minimum
            map[:message] = too_short
            map[:valid] = false
            throw(:valid, map)
          end

          if(maximum and(words.size > maximum))
            map[:message] = too_long
            map[:valid] = false
            throw(:valid, map)
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
            throw(:valid, map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            throw(:valid, map)
          end

          parts = value.split(/@/)

          unless parts.size == 2
            map[:valid] = false
            throw(:valid, map)
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
            throw(:valid, map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            throw(:valid, map)
          end

          parts = value.split(%r|://|)

          unless parts.size >= 2
            map[:valid] = false
            throw(:valid, map)
          end

          map
        end

      args.push(:message => message)
      validates(*args, &block)
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
            throw(:valid, map)
          end

          value = value.to_s.strip

          if value.empty? and allow_blank
            map[:valid] = true
            throw(:valid, map)
          end

          parts = value.scan(/\d+/)

          unless parts.size >= 1
            map[:valid] = false
            throw(:valid, map)
          end

          map
        end

      args.push(:message => message)
      validates(*args, &block)
    end

    def validates_presence_of(*args)
      options = Dao.options_for!(args)

      message = options[:message] || 'is blank or missing'

      allow_nil = options[:allow_nil]
      allow_blank = options[:allow_blank]

      block =
        lambda do |value|
          map = Dao.map(:valid => true)

          if value.nil?
            unless allow_nil
              map[:message] = message
              map[:valid] = false
              throw(:valid, map)
            end
          end

          value = value.to_s.strip

          if value.empty?
            unless allow_blank
              map[:message] = message
              map[:valid] = false
              throw(:valid, map)
            end
          end

          map
        end

      validates(*args, &block)
    end

    def validates_any_of(*args)
      options = Dao.options_for!(args)
      list = args

      list.each do |args|
        candidates = list.dup
        candidates.delete(args)

        message = options[:message] || "(or #{ candidates.map{|candidate| Array(candidate).join('.')}.join(', ') } ) is blank or missing"
        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        result = self.result

        block =
          lambda do |value|
            map = Dao.map(:valid => true)
            values = list.map{|key| result.get(key)}
            valid = false
            values.each do |val|
              if val
                valid = true
                break
              end

              if val.nil?
                if allow_nil
                  valid = true
                  break
                end
              end

              val = val.to_s.strip

              if val.empty?
                if allow_blank
                  valid = true
                  break
                end
              end
            end

            unless valid
              if value.nil?
                unless allow_nil
                  map[:message] = message
                  map[:valid] = false
                  throw(:valid, map)
                end
              end

              value = value.to_s.strip

              if value.empty?
                unless allow_blank
                  map[:message] = message
                  map[:valid] = false
                  throw(:valid, map)
                end
              end
            end

            map
          end
        validates(*args, &block)
      end
    end

    def validates_all_of(*args)
      options = Dao.options_for!(args)
      list = args

      list.each do |args|
        candidates = list.dup
        candidates.delete(args)

        message = options[:message] || "(and #{ candidates.map{|candidate| Array(candidate).join('.')}.join(', ') } ) is blank or missing"
        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        result = self.result

        block =
          lambda do |value|
            map = Dao.map(:valid => true)

            values = list.map{|key| result.get(key)}
            valid = true
            values.each do |val|
              if val
                break
              end

              if val.nil?
                unless allow_nil
                  valid = false
                  break
                end
              end

              val = val.to_s.strip

              if val.empty?
                unless allow_blank
                  valid = false
                  break
                end
              end
            end

            unless valid
              if value.nil?
                unless allow_nil
                  map[:message] = message
                  map[:valid] = false
                  throw(:valid, map)
                end
              end

              value = value.to_s.strip

              if value.empty?
                unless allow_blank
                  map[:message] = message
                  map[:valid] = false
                  throw(:valid, map)
                end
              end
            end

            map
          end
        validates(*args, &block)
      end
    end
  end

  def Validations.add(method_name, &block)
    ::Dao::Validations::Common.module_eval do
      define_method(method_name, &block)
    end
  end
end
