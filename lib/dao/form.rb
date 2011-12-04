module Dao
  class Form
  # for html generation
  #
    include Tagz.globally

    class << Form 
      include Tagz.globally
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
        catch(:name) do
          if @object.respond_to?(:name)
            throw :name, @object.name
          end
          if @object.instance_variable_defined?('@name')
            throw :name, @object.instance_variable_get('@name')
          end
          'form'
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

    fattr(:status) do
      status =
        catch(:status) do
          if @object.respond_to?(:status)
            throw :status, @object.status
          end
          if @object.instance_variable_defined?('@status')
            throw :status, @object.instance_variable_get('@status')
          end
          Status.new
        end

      case status
        when Status
          status
        else
          raise(ArgumentError.new("#{ status.inspect } (#{ status.class })"))
      end
    end

  # html generation methods 
  #
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

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))
      target = options.delete(:for) || id_for(keys)

      content =
        if block.nil? and !options.has_key?(:content)
          titleize(keys.last)
        else
          block ? block.call() : options.delete(:content)
        end

      label_(options_for(options, :for => target, :class => klass, :id => id, :data_error => error)){ content }
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

    def button(*args)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      type = options.delete(:type) || :button
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

      button_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){}
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
          block ? block.call(attributes.get(keys)) : options.delete(:value)
        end

      textarea_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ value.to_s }
    end

    def select(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      from = options.delete(:from) || options.delete(:options)
      blank = options.delete(:blank)

      selected =
        if options.has_key?(:selected)
          options.delete(:selected)
        else
          value_for(attributes, keys)
        end

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      block ||= lambda{|pair| pair = Array(pair).flatten.compact; [pair.first, pair.last, selected=nil]}

      if from.nil?
        key = keys.map{|key| "#{ key }"}
        key.last << "_options"
        from = attributes.get(*key) if attributes.has?(*key)
      end

      list = Array(from)

      case list.first
        when Hash, Array
          nil
        else
          list.flatten!
          list.compact!
          list.map!{|element| [element, element]}
      end

      case blank
        when nil, false
          nil
        when true
          list.push(nil)
        else
          list.unshift(blank)
      end

      selected_value =
        case selected
          when Array
            selected.first
          when Hash
            key = [:id, 'id', :value, 'value'].detect{|k| selected.has_key?(k)}
            key ? selected[key] : selected
          else
            selected
        end

      select_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){
        list.each do |pair|
          returned = block.call(pair)

          case returned
            when Array
              content, value, selected, *ignored = returned
            when Hash
              content = returned[:content]
              value = returned[:value]
              selected = returned[:selected]
            else
              content = returned
              value = returned
              selected = nil
          end

          value ||= content

          if selected.nil?
            selected = value.to_s==selected_value.to_s
          end

          opts = {:value => value}
          opts[:selected] = !!selected if selected
          option_(opts){ content }
        end
      }
    end

    def upload(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      default = Map.for(options.delete(:default))
      placeholder = options.delete(:placeholder)

      case placeholder
        when String, Symbol
          default[:url] = placeholder.to_s
        when Array
          case
            when placeholder.size == 1
              default[:url] = placeholder.last.to_s

            when placeholder.size > 1
              default[:url] = placeholder.last.to_s
              default[:path] = File.expand_path(placeholder.join('/'))
          end
        when Hash
          default.update(placeholder)
      end

      upload_cache = upload_cache_for(keys, :default => default)

      upload =
        tagz{
          input_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error, :type => 'file')){ }
          __
          tagz{ upload_cache.hidden }
        }

      upload.fattr(:cache){ upload_cache }

      upload
    end

    def upload_cache_for(keys, options = {})
      upload_cache = UploadCache.for(attributes, keys, options)
      upload_cache.name = name_for(upload_cache.cache_key)
      uploads[keys] = upload_cache
      upload_cache
    end

    def uploads(*key)
      return uploads[Array(key).flatten] unless key.empty?
      @uploads ||= Map.new
    end

    def uploaded(key)
      key = Array(key).flatten
      uploads[key]
    end
    alias_method('upload?', 'uploaded')

    def clear_caches!
      uploads.each do |key, upload|
        upload.clear!
      end
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
      Tagz.escapeHTML(value)
    end

    def Form.prefix_for(name)
      "dao[#{ name }]"
    end

    def Form.name_for(name, *keys)
      "#{ prefix_for(name) }[#{ Array(keys).flatten.compact.join('.') }]"
    end

    def name_for(*keys)
      Form.name_for(name, *keys)
    end

    def options_for(*hashes)
      map = Map.new
      hashes.flatten.each do |h|
        h.each{|k,v| map[attr_for(k)] = v unless v.nil?}
      end
      map
    end

    def slug_for(string)
      string = string.to_s
      words = string.to_s.scan(%r/\w+/)
      words.map!{|word| word.gsub(%r/[^0-9a-zA-Z_:-]/, '')}
      words.delete_if{|word| word.nil? or word.strip.empty?}
      words.join('-').downcase.sub(/_+$/, '')
    end

    def attr_for(string)
      slug_for(string).gsub(/_/, '-')
    end

    def titleize(string)
      string = string.to_s
      string = string.titleize if string.respond_to?(:titleize)
      string
    end
  end
end
