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
    attr_accessor :name
    attr_accessor :attributes
    attr_accessor :errors

    def initialize(object)
      @object = object
      @name = @object.name
      @attributes = @object.attributes
      @errors = @object.errors
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
          value_for(@attributes, keys)
        else
          block ? block.call(@attributes.get(keys)) : options.delete(:value)
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
          value_for(@attributes, keys)
        else
          block ? block.call(@attributes.get(keys)) : options.delete(:value)
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
          value_for(@attributes, keys)
        else
          block ? block.call(@attributes.get(keys)) : options.delete(:value)
        end

      textarea_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ value.to_s }
    end

    def select(*args, &block)
      options = args.extract_options!.to_options! 
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      from = options.delete(:from) || options.delete(:options) || @attributes.get(*keys)
      blank = options.delete(:blank)

      selected =
        if options.has_key?(:selected)
          options.delete(:selected)
        else
          value_for(@attributes, keys)
        end

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      block ||= lambda{|pair| pair = Array(pair).flatten.compact; [pair.first, pair.last, selected=nil]}

      if from.nil?
        key = keys.map{|key| "#{ key }"}
        key.last << "_options"
        from = @attributes.get(*key) if @attributes.has?(*key)
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
              value, content, selected, *ignored = returned
            when Hash
              value = returned[:value]
              content = returned[:content] || value
              selected = returned[:selected]
            else
              value = returned
              content = returned
              selected = nil
          end

          if selected.nil?
            selected = value.to_s==selected_value.to_s
          end

          opts = {:value => value}
          opts[:selected] = !!selected if selected
          option_(opts){ content }
        end
      }
    end

  # html generation support methods
  #
    def id_for(keys)
      id = [name, keys.join('-')].compact.join('_')
      slug_for(id)
    end

    def errors_on(keys)
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

    def Form.name_for(name, *keys)
      "dao[#{ name }][#{ Array(keys).flatten.compact.join('.') }]"
    end

    def name_for(keys)
      Form.name_for(@name, keys)
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
