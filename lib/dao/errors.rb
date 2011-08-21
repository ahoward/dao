module Dao
  class Errors
  # for html generation
  #
    include Tagz.globally

    class << Errors
      include Tagz.globally

      def for(*args, &block)
        new(*args, &block)
      end
    end

  # you can tweak these if you want
  #
    Global = '*' unless defined?(Global)
    Separator = "\342\207\222" unless defined?(Separator)  ### this is an "Open-outlined rightward arrow"
                                                           ### http://en.wikipedia.org/wiki/List_of_Unicode_characters#Supplemental_arrows-A
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
    attr_accessor :map
    attr_accessor :errors

    def initialize(map = nil)
      @map = map || Map.new
      @errors = Map.new
    end

    def method_missing(method, *args, &block)
      super unless @errors.respond_to?(method)
      @errors.send(method, *args, &block)
    end

    def [](*keys)
      if @errors.has?(keys)
        @errors.get(keys)
      else
        @errors.set(keys => [])
      end
    end

    def size
      size = 0
      @errors.depth_first_each{|key, val| size += Array(val).size}
      size
    end
    alias_method('count', 'size')
    alias_method('length', 'size')

    def add(*args)
      options = Map.options_for!(args)
      sticky = options[:sticky]
      clear = options[:clear]

      args.flatten!
      message = args.pop
      keys = args
      keys = [Global] if keys.empty?
      errors = Hash.new

      if Array(keys) == [Global]
        sticky = true unless options.has_key?(:sticky)
      end

      sticky = true if(message.respond_to?(:sticky?) and message.sticky?)

      if message
        if message.respond_to?(:full_messages)
          message.depth_first_each do |keys, msg|
            errors[keys] = Message.new(msg, :sticky => sticky)
          end
        else
          errors[keys] = Message.new(message, :sticky => sticky)
        end
      else
        raise(ArgumentError, 'no message!')
      end

      message = Message.new(message) unless message.is_a?(Message)

      result = []

      errors.each do |keys, message|
        list = @errors.get(keys)
        unless @errors.has?(keys)
          @errors.set(keys => [])
          list = @errors.get(keys)
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

    def clear!
      @errors.clear
    end

    def clear
      keep = []
      @errors.depth_first_each do |keys, message|
        index = keys.pop
        args = [keys, message].flatten
        keep.push(args) if message.sticky?
      end
      clear!
    ensure
      keep.each{|args| add!(*args)}
    end

    def invalid?(*keys)
      @errors.has?(keys) and !@errors.get(keys).nil?
    end

    alias_method('on?', 'invalid?')

    def on(*args, &block)
      @errors.get(*args, &block)
    end

    def full_messages
      global_messages = []
      full_messages = []

      @errors.depth_first_each do |keys, value|
        index = keys.pop
        key = keys.join('.')
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
      @errors.depth_first_each do |keys, message|
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
      css_class = options[:class] || 'errors conducer'

      to_html =
        table_(:class => css_class){
          caption_{ "We're so sorry, but can you please fix the following errors?" }
          errors.each do |e|
            e.full_messages.each do |key, message|
              at_least_one_error = true
              title = Array(key).join(' ').titleize
              tr_{
                td_(:class => :title){ title }
                td_(:class => :separator){ Separator }
                td_(:class => :message){ message }
              }
            end
          end
        }
      at_least_one_error ? to_html : '' 
    end

    def to_s(*args, &block)
      to_html(*args, &block)
    end

    def to_json(*args, &block)
      @errors.to_json(*args, &block)
    end
  end
end
