module Dao
  class Errors < ::Map
    include Tagz.globally

    class << Errors
      include Tagz.globally
    end

    Global = '*' unless defined?(Global)
    Separator = '⇒' unless defined?(Separator)

    class Message < ::String
      attr_accessor :sticky

      def initialize(*args)
        options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
        replace(args.join(' '))
        @sticky = options[:sticky]
      end

      def sticky?
        @sticky ||= nil
        !!@sticky
      end
    end

    class << Errors
      def global_key
        [Global]
      end

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

    def add(*args)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
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
      end

      result = []

      errors.each do |keys, message|
        list = get(keys)
        unless get(keys)
          set(keys => [])
          list = get(keys)
        end
        list.clear if clear
        list.push(message)
        result = list
      end
      
      result
    end
    alias_method 'add_to_base', 'add'

    def clone
      clone = Errors.new
      depth_first_each do |keys, message|
        args = [*keys]
        args.push(message)
        clone.add(*args)
      end
      clone
    end

    def add!(*args)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      options[:sticky] = true
      args.push(options)
      add(*args)
    end
    alias_method 'add_to_base!', 'add!'

    alias_method 'clear!', 'clear' unless instance_methods.include?('clear!')

    def update(other, options = {})
      options = Dao.map_for(options)
      prefix = Array(options[:prefix]).flatten.compact

      other.each do |key, val|
        key = key.to_s
        if key == 'base' or key == Global
          add!(val)
        else
          key = prefix + [key] unless prefix.empty?
          add(key, val)
        end
      end
    end

    def clear
      keep = []
      depth_first_each do |keys, message|
        index = keys.pop
        args = [keys, message].flatten
        keep.push(args) if message.sticky?
      end
      clear!
    ensure
      keep.each{|args| add!(*args)}
    end

    def invalid?(*keys)
      has?(keys) and !get(keys).nil?
    end

    alias_method 'on?', 'invalid?'

    alias_method 'on', 'get'

    def size
      size = 0
      depth_first_each{ size += 1 }
      size
    end

    alias_method 'count', 'size'
    alias_method 'length', 'size'

    def full_messages
      global_messages = []
      full_messages = []

      depth_first_each do |keys, value|
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
      depth_first_each do |keys, message|
        index = keys.pop
        message = message.to_s.strip
        next if message.empty?
        yield(keys, message)
      end
    end

    def each_full_message
      full_messages.each{|msg| yield msg}
    end

    alias_method 'each_full', 'each_full_message'

    def messages
      messages =
        (self[Global]||[]).map{|message| message}.
        select{|message| not message.strip.empty?}
    end

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
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      errors = [error, *args].flatten.compact

      at_least_one_error = false
      css_class = options[:class] || 'dao errors'

      to_html =
        table_(:class => css_class){
          caption_{ "We're so sorry, but can you please fix the following errors?" }
          errors.each do |e|
            e.full_messages.each do |key, message|
              at_least_one_error = true
              tr_{
                td_(:class => :key){ key }
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
  end
end
