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

      if message.is_a?(Hash) or message.respond_to?(:full_messages)
        message.each do |k, v|
          Array(v).each do |msg|
            add(key + [k], msg)
          end
        end
        return(self)
      end

      message = message.is_a?(Message) ? message : Message.new(message)
      message.source = source

      set(key => []) unless has?(key)
      list = get(key)
      list.clear if clear
      list.push(message)
      list.uniq!
      self
    end
    alias_method('add!', 'add')
    alias_method('add_to_base', 'add')
    alias_method('add_to_base!', 'add!')

# FIXME - this should accept an errors object
    def relay(*args)
      options = args.size > 1 ? Map.options_for!(args) : Map.new

      prefix = Array(options.delete(:prefix))

      args.flatten.compact.each do |source|
        errors = source.respond_to?(:errors) ? source.errors : source

        errors.each do |*argv|
          msgs = Array(argv.pop)

          # ref: support for key-style of https://github.com/glooko/mongoid-embedded-errors
          #key = Array(argv.pop).flatten.compact.join('.')
          #key = key.to_s.split('.') 
          #key.map!{|k| k =~ /\[(\d+)\]/ ? $1 : k}
          #key = prefix + key
           
          key = prefix + Array(argv.pop)

          msgs.each{|msg| add(Array(options[:key] || key), msg, options)}
        end
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
        _ = keys.pop
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
        _ = keys.pop
        message = message.to_s.strip
        yield(keys, message)
      end
    end

    def flatten
      hash = Hash.new

      depth_first_each do |keys, value|
        _ = keys.pop
        hash[keys] ||= []
        hash[keys].push("#{ value }")
      end

      hash
    end

    def each_full_message
      full_messages.each{|msg| yield msg}
    end

    alias_method('each_full', 'each_full_message')

    def messages
      (self[Global] || []).map{|message| message}
                          .select{|message| not message.strip.empty?}
    end

    def global
      reject{|k, v| k != Global}
    end

    def local
      reject{|k, v| k == Global}
    end

  # html generation methods
  #
    def to_html(*args)
      Errors.to_html(self, *args)
    end

    def Errors.to_html(*args, &block)
      if block
        define_method(:to_html, &block)
      else
        errors_to_html(*args)
      end
    end

    def Errors.errors_to_html(*args)
      Errors2Html.to_html(*args)
    end

    def to_s(format = :html, *args, &block)
      case format.to_s
        when /html/
          to_html(*args, &block)

        when /text/
          to_text(*args, &block)
      end
    end

    class KeyPrefixer
      attr_accessor :object
      attr_accessor :global

      def initialize(object)
        @object = object

        @prefix =
          if @object && @object.respond_to?(:model_name)
            @object.model_name.to_s.underscore
          else
            nil
          end

        @global = Array(Global)
      end

      def prefix(key)
        is_global_key = key == @global || Array(key) == @global

        if @prefix
          if is_global_key
            @prefix
          else
            ["#{ @prefix }.#{ key[0] }", *key[1..-1]]
          end
        else
          if is_global_key
            'global'
          else
            key
          end
        end
      end
    end

    def key_prefixer
      @key_prefixer ||= KeyPrefixer.new(object)
    end

    def prefix_key(key)
      key_prefixer.prefix(key)
    end

    def Errors.to_hash(*args)
      error = args.shift
      Map.options_for!(args)
      errors = [error, *args].flatten.compact

      map = Map.new

      errors.each do |e|
        e.full_messages.each do |key, message|
          k = e.key_prefixer.prefix(key)

          map.set(k, []) unless map.has?(k)
          map.get(k).push("#{ message }")
        end
      end

      map.to_hash
    end

    def to_hash
      Errors.to_hash(self)
    end

    def Errors.errors_to_text(*args)
      hash = to_hash(*args)

      if hash.empty?
        nil
      else
        hash.to_yaml
      end
    end

    def to_text
      Errors.errors_to_text(self)
    end
  end
end
