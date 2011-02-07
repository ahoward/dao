module Dao
  class Form
    include Tagz.globally

    class << Form 
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

    attr_accessor :result

    def initialize(*args, &block)
      @result = args.shift if args.first.is_a?(Result)
      super
    end

    def data
      result.data
    end

    def errors
      result.errors
    end

    def ==(other)
      result == other.result
    end

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

      name = options.delete(:name) || keys.last
      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      content =
        if block.nil? and !options.has_key?(:content) 
          name.to_s.humanize
        else
          block ? block.call() : options.delete(:content)
        end

      label_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ content }
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
          value_for(data, keys)
        else
          block ? block.call(data.get(keys)) : options.delete(:value)
        end

      input_(options_for(options, :type => type, :name => name, :value => value, :class => klass, :id => id, :data_error => error)){}
    end

    def submit(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      options[:type] = :submit
      options[:value] = block ? block.call : :Submit
      args.push(options)
      input(*args)
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
          value_for(data, keys)
        else
          block ? block.call(data.get(keys)) : options.delete(:value)
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
          value_for(data, keys)
        else
          block ? block.call(data.get(keys)) : options.delete(:value)
        end

      textarea_(options_for(options, :name => name, :class => klass, :id => id, :data_error => error)){ value.to_s }
    end

    def select(*args, &block)
      options = Dao.map_for(args.last.is_a?(Hash) ? args.pop : {})
      keys = args.flatten

      name = options.delete(:name) || name_for(keys)
      from = options.delete(:from) || options.delete(:select) || options.delete(:all) || options.delete(:list)

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      block ||= lambda{|pair| pair = Array(pair).flatten.compact; [pair.first, pair.last, selected=false]}

      list = Array(from)
      case list.first
        when Hash, Array
          nil
        else
          list.flatten!
          list.compact!
          list.map!{|element| [element, element]}
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
              selected = false
          end
          opts = {:value => value}
          opts[:selected] = !!selected if selected
          option_(opts){ content }
        end
      }
    end

    def id_for(keys)
      id = [result.path, keys.join('-')].compact.join('_')
      slug_for(id)
    end

    def class_for(keys, klass = nil)
      klass = 
        if result.errors.on?(keys)
          [klass, 'dao', 'errors'].compact.join(' ')
        else
          [klass, 'dao'].compact.join(' ')
        end
      klass
    end

    def error_for(keys, klass = nil)
      if result.errors.on?(keys)
        result.errors.get(keys)
      end
    end

    def value_for(data, keys)
      return nil unless data.has?(keys)
      value = Tagz.escapeHTML(data.get(keys))
    end

    def name_for(keys)
      "#{ result.path }(#{ Array(keys).flatten.compact.join(',') })"
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
  end
end
