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
      list
      self
    end
    alias_method('add!', 'add')
    alias_method('add_to_base', 'add')
    alias_method('add_to_base!', 'add!')

    def relay(*args)
      options = args.size > 1 ? Map.options_for!(args) : Map.new

      prefix = Array(options.delete(:prefix))

      args.flatten.compact.each do |source|
        errors = source.respond_to?(:errors) ? source.errors : source

        errors.each do |*argv|
          msgs = Array(argv.pop)
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

    def flatten
      hash = Hash.new

      depth_first_each do |keys, value|
        index = keys.pop
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
      messages =
        (self[Global]||[]).map{|message| message}.
        select{|message| not message.strip.empty?}
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
      Errors.to_html(errors=self, *args)
    end

    def Errors.to_html(*args, &block)
      if block
        define_method(:to_html, &block)
      else
        errors_to_html(*args)
      end
    end

    def Errors.errors_to_html(*args)
      error = args.shift
      options = Map.options_for!(args)
      errors = [error, *args].flatten.compact

      at_least_one_error = false

      global_errors = []
      field_errors = Hash.new{|h,k| h[k] = []}

      errors.each do |e|
        e.full_messages.each do |key, message|
          at_least_one_error = true

          type = Array(key) == Array(Global) ? "global" : "field"

          case type
            when 'global'
              global_errors.push(message).uniq!

            when 'field'
              field_errors[key].push(message).uniq!
          end
        end
      end

      return "" unless at_least_one_error


      div_(:class => errors_css[:container]){
        __
        h3_(:class => errors_css[:heading]){ "Sorry, we encountered some errors:" }
        __

        unless global_errors.empty?
          ol_(:class => "global #{ errors_css[:list] }"){
          __
            global_errors.each do |message|
              li_(:class => errors_css[:message]){ message }
              __
            end
          }
          __
        end

        unless field_errors.empty?
          dl_(:class => "field #{ errors_css[:list] }"){
          __
            field_errors.each do |key, messages|
              title = Array(key).join(" ").titleize

              dt_(:class => errors_css[:title]){ title }
              __

              messages.each do |message|
                dd_(:class => errors_css[:message]){ message }
                __
              end
            end
          }
          __
        end
      }
    end

  # Errors.errors_css[:container] += " alert alert-error"
  #
    def Errors.errors_css
      @errors_css ||= Map.new(
        :container => "dao errors summary",

        :heading   => "caption",

        :list      => "list",

        :message   => "message",

        :title     => "title"
      )
    end

    def Errors.default_errors_to_html(*args)
      Errors.errors_to_html(*args)
    end

    def to_s(*args, &block)
      to_html(*args, &block)
    end

    def Errors.to_hash(*args)
      error = args.shift
      options = Map.options_for!(args)
      errors = [error, *args].flatten.compact

      map = Map.new
      map[:global] = []

      errors.each do |e|
        e.full_messages.each do |key, message|
          at_least_one_error = true

          type = Array(key) == Array(Global) ? "global" : "field"

          case type
            when 'global'
              map[:global].push("#{ message }")

            when 'field'
              k = [:fields, *key]
              unless map.has?(k)
                map.set(k, [])
              end
              map.get(k).push("#{ message }")
          end
        end
      end

      map.to_hash
    end

    def to_hash
      Errors.to_hash(self)
    end

    def Errors.errors_to_text(*args)
      to_hash(*args).to_yaml
    end

    def to_text
      Errors.errors_to_text(self)
    end
  end
end
