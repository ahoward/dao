module Dao
  class Errors < ::Map
  # for html generation
  #
    include Tagz.globally

    class << Errors
      include Tagz.globally

      def for(*args, &block)
        if args.size == 1 and args.first.is_a?(Errors)
          return args.first
        end
        new(*args, &block)
      end
    end

  # you can tweak these if you want
  #
    Global = '*' unless defined?(Global)
    #Separator = "\342\207\222" unless defined?(Separator)  ### this is an "Open-outlined rightward arrow"
    Separator = ":" unless defined?(Separator)

  # messages know when they're sticky
  #
    class Message < ::String
      attr_accessor :sticky

      def initialize(*args)
        options = Map.options_for!(args)
        replace(args.join(' '))
        @sticky = options[:sticky]
      end

      def sticky?
        @sticky ||= nil
        !!@sticky
      end

      def to_s
        self
      end
    end

  # class methods
  #
    class << Errors
      def global_key
        [Global]
      end
    end

  # instance methods
  #
    attr_accessor :object

    def initialize(*args)
      @object = args.shift
    end

    def errors
      self
    end

    def [](key)
      self[key] = Array.new unless has_key?(key)
      super
    end

    def size
      inject(0){|size, kv| size + Array(kv.last).size}
    end
    alias_method('count', 'size')
    alias_method('length', 'size')

    def add(*args)
      options = Map.options_for!(args)
      sticky = options[:sticky]
      clear = options[:clear]

      args.flatten!
      message = args.pop
      key = args
      key = [Global] if key.empty?
      new_errors = Hash.new

      if Array(key) == [Global]
        sticky = true unless options.has_key?(:sticky)
      end

      sticky = true if(message.respond_to?(:sticky?) and message.sticky?)

      if message
        if message.respond_to?(:full_messages)
          message.full_messages.each do |k, msg|
            new_errors[k] = Message.new(msg, :sticky => sticky)
          end
        else
          new_errors[key] = Message.new(message, :sticky => sticky)
        end
      else
        raise(ArgumentError, 'no message!')
      end

      message = Message.new(message) unless message.is_a?(Message)

      result = []

      new_errors.each do |keys, message|
        list = get(keys)

        unless has?(keys)
          set(keys => [])
          list = get(keys)
        end

        list.clear if clear
        list.push(message)

        result = list
      end
      
      result
    end

    alias_method('add_to_base', 'add')

    def add!(*args)
      options = Map.new(args.last.is_a?(Hash) ? args.last : {}) 
      options[:sticky] = true
      args.push(options)
      add(*args)
    end

    alias_method('add_to_base!', 'add!')

    alias_method('clear!', 'clear')

    def clear
      keep = []
      each do |keys, messages|
        messages.each do |message|
          args = [keys, message].flatten
          keep.push(args) if message.sticky?
        end
      end
      clear!
    ensure
      keep.each{|args| add!(*args)}
    end

    def invalid?(*keys)
      has?(keys) and !get(keys).nil?
    end

    alias_method('on?', 'invalid?')

    def on(*args, &block)
      get(*args, &block)
    end

    def full_messages
      global_messages = []
      full_messages = []

      depth_first_each do |keys, value|
        index = keys.pop
        key = keys
        #key = keys.join('.')
        value = value.to_s
        next if value.strip.empty?
        if key == Global
          global_messages.push([key, value])
        else
          full_messages.push([key, value])
        end
      end

      global_messages + full_messages
    end

    def each_message
      depth_first_each do |keys, message|
        index = keys.pop
        message = message.to_s.strip
        yield(keys, message)
      end
    end

    def each_full_message
      full_messages.each{|msg| yield msg}
    end

    alias_method('each_full', 'each_full_message')

    def messages
      messages =
        (self[Global]||[]).map{|message| message}.
        select{|message| not message.strip.empty?}
    end

  # html generation methods
  #
    def to_html(*args)
      Errors.to_html(errors=self, *args)
    end

    def Errors.to_html(*args, &block)
      if block
        define_method(:to_html, &block)
      else
        default_errors_to_html(*args)
      end
    end

    def Errors.default_errors_to_html(*args)
      error = args.shift
      options = Map.options_for!(args)
      errors = [error, *args].flatten.compact

      at_least_one_error = false
      css_class = options[:class] || 'errors dao'

      to_html =
        div_(:class => css_class){
          __

          div_(:class => :caption){ "We're so sorry, but can you please fix the following errors?" }
          __

          ul_{
            __
            errors.each do |e|
              e.full_messages.each do |key, message|
                at_least_one_error = true
                title = Array(key).join(' ').titleize

                error_class = Array(key)==Array(Global) ? "global-error" : "field-error"
                title_class = "title"
                separator_class = "separator"
                message_class = "message"

                li_(:class => error_class){
                  span_(:class => title_class){ title }
                  span_(:class => separator_class){ " #{ Separator } " }
                  span_(:class => message_class){ message }
                }
                __
              end
            end
            __
          }
          __
        }

      at_least_one_error ? to_html : '' 
    end

    def to_s(*args, &block)
      to_html(*args, &block)
    end
  end
end
