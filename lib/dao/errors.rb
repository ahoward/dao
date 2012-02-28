# -*- encoding : utf-8 -*-
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
    Separator = "\342\207\222" unless defined?(Separator)  ### this is an "Open-outlined rightward arrow"
    #Separator = ":" unless defined?(Separator)

  # messages know when they're sticky
  #
    class Message < ::String
      attr_accessor :source

      def initialize(*args)
        options = Map.options_for!(args)
        replace(args.join(' '))
        self.source = options[:source]
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

    def [](key)
      return [] unless has_key?(key)
      super
    end

    def errors
      self
    end

    def size
      size = 0
      depth_first_each do |keys, value|
        size += Array(value).size
      end
      size
    end
    alias_method('count', 'size')
    alias_method('length', 'size')

    def empty?
      size == 0
    end

    def add(*args)
      return relay(args.first) if args.size == 1 and relay?(args.first)
      options = Map.options_for!(args)

      clear = options[:clear]
      source = options[:source]

      args.flatten!

      message = args.pop or raise(ArgumentError, 'no message!')
      key = args.empty? ? [Global] : args

      message = message.is_a?(Message) ? message : Message.new(message)
      message.source = source

      set(key => []) unless has?(key)
      list = get(key)
      list.clear if clear
      list.push(message)
      list.uniq!
      list
      self
    end
    alias_method('add!', 'add')
    alias_method('add_to_base', 'add')
    alias_method('add_to_base!', 'add!')

    def relay(other, options = {})
      case
        when other.respond_to?(:each)
          other.each do |key, messages|
            Array(messages).each do |message|
              add(key, message, options = {})
            end
          end
        when other.respond_to?(:each_pair)
          other.each_pair do |key, messages|
            Array(messages).each do |message|
              add(key, message, options = {})
            end
          end

        when other.respond_to?(:each_slice)
          Array(other).flatten.each_slice(2) do |key, messages|
            Array(messages).each do |message|
              add(key, message, options = {})
            end
          end

        else
          raise(ArgumentError, other.class.name)
      end
      self
    end

    def relay?(arg)
      [:each, :each_pair, :each_slice].any?{|method| arg.respond_to?(method)}
    end

    def add_from_source(keys, callback, message)
      add(keys, message, :source => callback)
      self
    end

    def delete_from_source(keys, callback)
      if((messages = errors.on(keys)))
        messages.delete_if{|m| m.respond_to?(:source) and m.source==callback}
        rm(*keys) if messages.empty?
      end
      self
    end

    def clear
      super
    end
    alias_method('clear!', 'clear')

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

      emap = Map.new

      errors.each do |e|
        e.full_messages.each do |key, message|
          at_least_one_error = true
          emap[key] ||= message
        end
      end

      return "" unless at_least_one_error

      div_(:class => "dao errors summary"){
        __

        h3_(:class => "caption"){ "We're so sorry, but can you please fix the following errors?" }
        __

        dl_(:class => "list"){
          emap.each do |key, message|
            title = Array(key).join(" ").titleize

            type = Array(key) == Array(Global) ? "global" : "field"

            dt_(:class => "title #{ type }"){ title }
            dd_(:class => "message #{ type }"){ message }
          end
        }
        __
      }
    end

    def to_s(*args, &block)
      to_html(*args, &block)
    end
  end
end
