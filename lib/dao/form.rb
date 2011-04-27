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
    attr_accessor :map

    def initialize(*args, &block)
      @map = args.first.is_a?(Map) ? args.shift : Map.new
    end

    def errors
      @map.errors
    end

    def path
      @map.path
    end



  # html generation methods 
  #
    def form(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
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
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      keys = args.flatten

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))
      target = options.delete(:for) || id_for(keys)

      content =
        if block.nil? and !options.has_key?(:content)
          humanize(keys.last)
        else
          block ? block.call() : options.delete(:content)
        end

      label_(options_for(options, :for => target, :class => klass, :id => id, :data_error => error)){ content }
    end

    def input(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      keys = args.flatten

      type = options.delete(:type) || :text
      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      value =
        if block.nil? and !options.has_key?(:value) 
          value_for(@map, keys)
        else
          block ? block.call(@map.get(keys)) : options.delete(:value)
        end

      input_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){}
    end

    def submit(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})

      content = block ? block.call : (args.first || 'Submit')

      options[:name] ||= :submit
      options[:type] ||= :submit
      options[:value] ||= content

      input_(options_for(options)){}
    end

    def button(*args)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      keys = args.flatten

      type = options.delete(:type) || :button
      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      value =
        if block.nil? and !options.has_key?(:value) 
          value_for(@map, keys)
        else
          block ? block.call(@map.get(keys)) : options.delete(:value)
        end

      button_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){}
    end

    def reset(*args)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      options[:type] = :reset
      args.push(options)
      button(*args)
    end

    def textarea(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      value =
        if block.nil? and !options.has_key?(:value) 
          value_for(@map, keys)
        else
          block ? block.call(@map.get(keys)) : options.delete(:value)
        end

      textarea_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ value.to_s }
    end

    def select(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      from = options.delete(:from) || options.delete(:options)
      blank = options.delete(:blank)

      selected =
        if options.has_key?(:selected)
          options.delete(:selected)
        else
          value_for(@map, keys)
        end

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      block ||= lambda{|pair| pair = Array(pair).flatten.compact; [pair.first, pair.last, selected=nil]}

      if from.nil?
        key = keys.map{|key| "#{ key }"}
        key.last << "_options"
        from = @map.get(*key) if @map.has?(*key)
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
      id = [path, keys.join('-')].compact.join('_')
      slug_for(id)
    end

    def class_for(keys, klass = nil)
      klass = 
        if errors.on?(keys)
          [klass, 'dao', 'errors'].compact.join(' ')
        else
          [klass, 'dao'].compact.join(' ')
        end
      klass
    end

    def error_for(keys, klass = nil)
      errors.get(keys) if errors.on?(keys)
    end

    def value_for(map, keys)
      return nil unless map.has?(keys)
      value = Tagz.escapeHTML(map.get(keys))
    end

    def Form.name_for(path, *keys)
      path = Path.new(path) unless path.is_a?(Path)
      "#{ path }(#{ Array(keys).flatten.compact.join(',') })"
    end

    def Form.name_re_for(path)
      path = Path.new(path) unless path.is_a?(Path)
      Regexp.new(/^#{ Regexp.escape(path) }/)
    end

    def Form.encoded?(path, params)
      name_re = Form.name_re_for(path)
      params.keys.any?{|key| name_re =~ key.to_s}
    end

    def name_for(keys)
      Form.name_for(path, keys)
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

    def humanize(string)
      string = string.to_s
      string = string.humanize if string.respond_to?(:humanize)
      string
    end
  end
end
