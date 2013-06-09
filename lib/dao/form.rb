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
      def Builder.new(object_name, object, view, options, block)
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

    def initialize(*args)
      @object = args.shift
    end

    fattr(:attributes) do
      attributes =
        catch(:attributes) do
          if @object.respond_to?(:attributes)
            throw :attributes, @object.attributes
          end
          if @object.instance_variable_defined?('@attributes')
            throw :attributes, @object.instance_variable_get('@attributes')
          end
          if @object.is_a?(Map)
            throw :attributes, @object
          end
          if @object.respond_to?(:to_map)
            throw :attributes, Map.new(@object.to_map)
          end
          if @object.is_a?(Hash)
            throw :attributes, Map.new(@object)
          end
          if @object.respond_to?(:to_hash)
            throw :attributes, Map.new(@object.to_hash)
          end
          Map.new
        end

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
        catch(:errors) do
          if @object.respond_to?(:errors)
            throw :errors, @object.errors
          end
          if @object.instance_variable_defined?('@errors')
            throw :errors, @object.instance_variable_get('@errors')
          end
          Errors.new
        end

      case errors
        when Errors
          errors
        else
          raise(ArgumentError.new("#{ errors.inspect } (#{ errors.class })"))
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
    def element(which, *args, &block)
      send(which, *args, &block)
    end

    def form(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      action = options.delete(:action) || './'
      method = options.delete(:method) || 'post'
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      content =
        if block.nil? and !options.has_key?(:content)
          ''
        else
          block ? block.call(form=self) : options.delete(:content)
        end

      form_(options_for(options, :action => action, :method => method, :class => klass, :id => id, :data_error => error)){ content }
    end

    def label(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

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
      keys = args.flatten

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

      content = block ? block.call : (args.first || 'Submit')

      options[:name] ||= :submit
      options[:type] ||= :submit
      options[:value] ||= content

      input_(options_for(options)){}
    end

    def button(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      type = options.delete(:type) || :button
      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      value = options.has_key?(:value) ? options.delete(:value) : value_for(attributes, keys)

      content = (block ? block.call : (options.delete(:content) || 'Submit'))

      button_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){ content }
    end

    def radio_button(*args, &block)
      options = args.extract_options!.to_options!
      keys = args.flatten

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

      input_(options_for(options, :type => :radio, :name => name, :class => klass, :id => id, :data_error => error)){}
    end

    def checkbox(*args, &block)
      options = args.extract_options!.to_options!
      keys = args.flatten

      type = options.delete(:type) || :checkbox
      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))
      values = options.delete(:values) || options.delete(:checked)

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
            t, f, *ignored = Array(values).flatten.compact
            {true => t, false => f}
        end
      value_for[true] ||= '1'
      value_for[false] ||= '0'

      hidden_options =
        options.dup.tap{|o| o.delete(:checked)}

      tagz{
        input_(options_for(hidden_options, :type => :hidden, :name => name, :value => value_for[false])){}

        __

        input_(
          options_for(
            options,
            :type => :checkbox,
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
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      value =
        if block.nil? and !options.has_key?(:value) 
          value_for(attributes, keys)
        else
          html_safe(block ? block.call(attributes.get(keys)) : options.delete(:value))
        end

      textarea_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ value.to_s }
    end

    def select(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      values = options.delete(:values) || options.delete(:options) || options.delete(:from)

      has_blank = options.has_key?(:blank) && options[:blank] != false
      blank = options.delete(:blank)

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      if values.nil?
        key = keys.map{|key| "#{ key }"}
        key.last << "_options"
        values = attributes.get(*key) if attributes.has?(*key)
      end

      if options[:multiple]
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
                content, value, selected, *ignored = returned
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
        end
      }
    end

    def upload(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

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

  # html generation support methods
  #
    def id_for(keys)
      id = [name, keys.join('-')].compact.join('_')
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
      html_safe(value)
    end

    def html_safe(value)
      value ||= ''
      value.respond_to?(:html_safe) ? value : CGI.escapeHTML(value)
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
      slug_for(string).gsub(/_/, '-')
    end

    def data_attr_for(string)
      "data-#{ attr_for(string) }"
    end

    def slug_for(string)
      string = string.to_s
      words = string.to_s.scan(%r/\w+/)
      words.map!{|word| word.gsub(%r/[^0-9a-zA-Z_:-]/, '')}
      words.delete_if{|word| word.nil? or word.strip.empty?}
      words.join('-').downcase.sub(/_+$/, '')
    end

    def titleize(string)
      string = string.to_s
      string = string.titleize if string.respond_to?(:titleize)
      string
    end
  end
end
