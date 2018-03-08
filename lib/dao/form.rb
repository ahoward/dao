# -*- encoding : utf-8 -*-
module Dao
  class Form
  # for html generation
  #
    include Tagz.globally

    class << Form 
      include Tagz.globally
    end

  # builder stuff for compatibity with rails' form_for()
  #
    class Builder < Form
      def Builder.new(object_name, object, view, options, block=:rails_3_4_5)
        if object.respond_to?(:form)

          html = options[:html] || {}
          html[:class] ||= 'dao'
          unless html[:class] =~ /(\s|\A)dao(\Z|\s)/o
            html[:class] << ' dao dao-form'
          end

          object.form
        else
          raise ArgumentError, object.class.name
        end
      end
    end

  # class methods
  #
    class << Form 
      def for(*args, &block)
        new(*args, &block)
      end
    end

  # instance methods
  #
    attr_accessor :object
    attr_accessor :unscoped

    def initialize(*args)
      @object = args.shift
      @unscoped = Map.new
      @scope = []
    end

    fattr(:attributes) do
      attributes =
        case
          when @object.respond_to?(:attributes)
            @object.attributes
          when @object.instance_variable_defined?('@attributes')
            @object.instance_variable_get('@attributes')
          when @object.is_a?(Map)
            @object
          when @object.respond_to?(:to_map)
            Map.new(@object.to_map)
          when @object.is_a?(Hash)
            Map.new(@object)
          when @object.respond_to?(:to_hash)
            Map.new(@object.to_hash)
          else
            Map.new
        end

      @unscoped[:attributes] =
        case attributes
          when Map
            attributes
          when Hash
            Map.new(attributes)
          else
            raise(ArgumentError.new("#{ attributes.inspect } (#{ attributes.class })"))
        end
    end

    fattr(:name) do
      name =
        case
          when @object.respond_to?(:form_name)
            @object.form_name
          when @object.respond_to?(:name)
            @object.name
          when @object.instance_variable_defined?('@form_name')
            @object.instance_variable_get('@form_name')
          when @object.instance_variable_defined?('@name')
            @object.instance_variable_get('@name')
          else
            :form
        end

      case name
        when Symbol, String
          name.to_s
        else
          raise(ArgumentError.new("#{ name.inspect } (#{ name.class })"))
      end
    end

    fattr(:errors) do
      errors =
        case
          when @object.respond_to?(:errors)
            @object.errors
          when @object.instance_variable_defined?('@errors')
            @object.instance_variable_get('@errors')
          else
            Errors.new
        end

      @unscoped[:errors] =
        case errors
          when Errors
            errors
          else
            raise(ArgumentError.new("#{ errors.inspect } (#{ errors.class })"))
        end
    end

    fattr(:messages) do
      messages =
        case
          when @object.respond_to?(:messages)
            @object.messages
          when @object.instance_variable_defined?('@messages')
            @object.instance_variable_get('@messages')
          else
            Messages.new
        end

      case messages
        when Messages
          messages
        else
          raise(ArgumentError.new("#{ messages.inspect } (#{ messages.class })"))
      end
    end

  # support for rails' forms...
  #
    fattr(:multipart){ true }

    %w( [] []= get set has has? ).each do |method|
      class_eval <<-__
        def #{ method }(*args, &block)
          attributes.#{ method }(*args, &block)
        end
      __
    end

  # html generation methods 
  #
    module Elements
      def element(which, *args, &block)
        send(which, *args, &block)
      end

      def form(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        action = options.delete(:action) || './'
        method = options.delete(:method) || 'post'
        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        content =
          if block.nil? and !options.has_key?(:content)
            ''
          else
            block ? block.call(self) : options.delete(:content)
          end

        form_(options_for(options, :action => action, :method => method, :class => klass, :id => id, :data_error => error)){ content }
      end

      def label(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        block ||=
          proc do
            options.delete(:content) ||
            options.delete(:value) ||
            keys.map{|key| key.to_s.titleize}.join(' ')
          end

        id = options.delete(:id) || id_for(keys + [:label])
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))
        target = options.delete(:for) || id_for(keys)

        label_(options_for(options, :for => target, :class => klass, :id => id, :data_error => error), &block)
      end

      def input(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        type = options.delete(:type) || :text
        name = options.delete(:name) || name_for(keys)
        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        value =
          if block.nil? and !options.has_key?(:value) 
            value_for(attributes, keys)
          else
            block ? block.call(attributes.get(keys)) : options.delete(:value)
          end

        input_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){}
      end

      def submit(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        keys.push(:submit) if keys.empty?
        name = options.delete(:name) || name_for(keys)

        content = block ? block.call : (args.first || 'Submit')

        options[:name] ||= name
        options[:type] ||= :submit
        options[:value] ||= content

        input_(options_for(options)){}
      end

      def button(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        type = options.delete(:type) || :button
        name = options.delete(:name) || name_for(keys)
        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        value = options.has_key?(:value) ? options.delete(:value) : value_for(attributes, keys)

        content = (block ? block.call : (options.delete(:content) || 'Submit'))

        content = escape_html(content)

        button_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){ content }
      end

      def radio_button(*args, &block)
        options = args.extract_options!.to_options!
        keys = scope(args)

        type = options.delete(:type) || :radio
        name = options.delete(:name) || name_for(keys)
        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        unless options.has_key?(:checked)
          checked =
            if options.has_key?(:value) and attributes.has?(keys)
              a = attributes.get(keys)
              b = options[:value]
              a==b or a.to_s==b.to_s
            else
              false
            end
          options[:checked] = checked if checked
        end

        input_(options_for(options, :type => type, :name => name, :class => klass, :id => id, :data_error => error)){}
      end

      def checkbox(*args, &block)
        options = args.extract_options!.to_options!
        keys = scope(args)

        type = options.delete(:type) || :checkbox
        name = options.delete(:name) || name_for(keys)
        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))
        values = options.delete(:values)

        unless options.has_key?(:checked)
          checked = Coerce.boolean(attributes.get(keys))
          options[:checked] = checked if checked
        end

        value_for =
          case values
            when false, nil
              {true => '1', false => '0'}
            when Hash
              h = {}
              values.map{|k, v| h[ k =~ /t|1|on|yes/ ? true : false ] = v}
              h
            else
              t, f, *_ = Array(values).flatten.compact
              {true => t, false => f}
          end
        value_for[true] ||= '1'
        value_for[false] ||= '0'

        hidden_options =
          options.dup.tap{|o| [:checked, :required, :disabled].each{|k| o.delete(k)}}

        tagz{
          input_(options_for(hidden_options, :type => :hidden, :name => name, :value => value_for[false])){}

          __

          input_(
            options_for(
              options,
              :type => type,
              :name => name,
              :value => value_for[true],
              :class => klass,
              :id => id,
              :data_error => error
            )
          ){}
        }
      end

      def hidden(*args, &block)
        options = args.extract_options!.to_options!
        options[:type] = :hidden
        args.push(options)
        input(*args, &block)
      end

      def reset(*args)
        options = args.extract_options!.to_options! 
        options[:type] = :reset
        args.push(options)
        button(*args)
      end

      def textarea(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        name = options.delete(:name) || name_for(keys)
        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        value =
          if block.nil? and !options.has_key?(:value) 
            value_for(attributes, keys)
          else
            block ? block.call(attributes.get(keys)) : options.delete(:value)
          end

        value = escape_html(value)

        textarea_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ value }
      end

      def select(*args, &block)
        options = args.extract_options!.to_options!
        keys = scope(args)

        name = options.delete(:name) || name_for(keys)
        values = options.delete(:values) || options.delete(:options) || options.delete(:from)

        has_blank = options.has_key?(:blank) && options[:blank] != false
        blank = options.delete(:blank)

        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        if values.nil?
          key = keys.map{|k| "#{k}"}
          key.last << "_options"
          values = attributes.get(*key) if attributes.has?(*key)
        end

        if options[:multiple]
          name = name.to_s
          name += '[]'
        end

        list = Array(values).map{|value| value.dup rescue value} # ensure list is dup'd

        case list.first
          when Hash, Array
            nil
          else
            list.flatten!
            list.compact!
            list.map!{|element| [element, element]}
        end

        if has_blank
          case blank
            when false
              blank = nil
            when nil, true
              blank = [nil, nil]
            else
              blank = [Array(blank).first, '']
          end
        end

        selected_value =
          if options.has_key?(:selected)
            options.delete(:selected)
          else
            attributes.get(keys)
          end

        selected_values = {}

        Array(selected_value).flatten.compact.each do |val|
          selected_values[val.to_s] = true
        end

        select_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){
          if blank
            content = blank.first || ''
            value = blank.last
            value.nil? ? option_(){ content } : option_(:value => value){ content }
          end

          unless list.empty?
            list.each do |pair|
              returned = block ? Dao.call(block, :call, pair.first, pair.last, selected_value) : pair 

              opts = Map.new
              selected = nil

              case returned
                when Array
                  content, value, selected, *_ = returned
                  if value.is_a?(Hash)
                    map = Map.for(value)
                    value = map.delete(:value)
                    selected = map.delete(:selected)
                    opts.update(map)
                  end

                when Hash
                  content = returned[:content]
                  value = returned[:value]
                  selected = returned[:selected]

                else
                  content = returned
                  value = returned
                  selected = nil
              end

              if selected.nil?
                selected = selected_values.has_key?(value.to_s)
              end

              opts[:value] = (value.nil? ? content : value)
              opts[:selected] = Coerce.boolean(selected) if selected

              option_(opts){ content }
            end
          else
            ' '
          end
        }
      end

      def upload(*args, &block)
        options = args.extract_options!.to_options! 
        keys = scope(args)

        cache_key = keys + [:cache]
        file_key = keys + [:file]

        cache_name = options.delete(:cache_name) || name_for(cache_key)
        file_name = options.delete(:file_name) || options.delete(:name) || name_for(file_key)

        id = options.delete(:id) || id_for(keys)
        klass = class_for(keys, options.delete(:class))
        error = error_for(keys, options.delete(:error))

        cache_value = attributes.get(cache_key)

        tagz{
          input_(:name => cache_name, :value => cache_value, :type => :hidden){ }

          __

          input_(options_for(options, :name => file_name, :class => klass, :id => id, :data_error => error, :type => :file)){ }
        }
      end
    end
    include Elements

  # html generation support methods
  #
    def id_for(keys)
      id = [name, keys.join('-')].compact.join('--')
      slug_for(id)
    end

    def errors_on(keys)
      errors.get(keys)
    end

    def errors_on?(*keys)
      !errors_on(keys).blank?
    end

    def class_for(keys, klass = nil)
      klass = 
        if errors_on?(keys)
          [klass, 'dao', 'errors'].compact.join(' ')
        else
          [klass, 'dao'].compact.join(' ')
        end
      klass
    end

    def error_for(keys, klass = nil)
      if errors_on?(keys)
        title = Array(keys).join(' ').titleize
        messages = Array(errors.get(keys)).join(', ')
        "#{ title }: #{ messages }"
      end
    end

    def value_for(map, keys)
      return nil unless map.has?(keys)

      value = map.get(keys)

      value =
        case value
          when Hash, Array
            value.to_json
          else
            value
        end

      value.to_s
    end

    def escape_html(string)
      Tagz.escape_html(string)
    end

    def Form.prefix_for(name)
      "dao[#{ name }]"
    end

    def Form.name_for(name, *keys)
      "#{ prefix_for(name) }[#{ key_for(*keys) }]"
    end

    def Form.key_for(*keys)
      keys.flatten.compact.map do |key|
        case
          when Integer === key
            key
          when key =~ /^\d+$/
            "~#{ key }"
          else
            key
        end
      end.join('.')
    end

    def key_for(*keys)
      Form.key_for(name, *keys)
    end

    def name_for(*keys)
      Form.name_for(name, *keys)
    end

    def scope(*keys, &block)
      if block.nil?
        return [@scope, *keys].flatten.compact
      end

      #attributes = self.attributes
      #errors = self.errors

      scope = @scope
      @scope = Coerce.list_of_strings(keys)

      #@attributes = Map.for(attributes.get(*@scope))
      #@errors = Errors.new.tap{|e| e.update(errors.get(*@scope))}

#p '@scope' => @scope
#p '@errors' => @errors
#p '@attributes' => @attributes
#p 'errors' => errors
#p 'attributes' => attributes
#puts
#abort
      begin
        argv = block.arity == 0 ? [@scope] : []
        block.call(*argv)
      ensure
        @scope = scope
        #@attributes = attributes
        #@errors = errors
      end
    end
    alias_method(:scope_for, :scope)

    def options_for(*hashes)
      map = Map.new

      hashes.flatten.each do |h|
        case((data = h.delete(:data) || h.delete('data')))
          when Hash
            data.each{|k,v| map[data_attr_for(k)] = v unless v.nil?}
          else
            h[:data] = data
        end

        h.each do |k,v|
          map[attr_for(k)] = v unless v.nil?
        end
      end

      %w( readonly disabled autofocus checked multiple ).each do |attr|
        map.delete(attr) unless Coerce.boolean(map[attr])
      end

      map
    end

    def attr_for(string)
      slug_for(string)
    end

    def data_attr_for(string)
      "data-#{ attr_for(string) }"
    end

    def slug_for(string)
      string = string.to_s
      words = string.scan(%r/[^\s]+/)
      words.join('--').downcase
    end

    def titleize(string)
      string = string.to_s
      string = string.titleize if string.respond_to?(:titleize)
      string
    end

    def capture(*args, &block)
      tagz(*args, &block)
    end
  end
end
