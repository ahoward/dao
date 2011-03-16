module Dao
  class Presenter
    include Tagz.globally

    class << Presenter 
      def for(*args, &block)
        new(*args, &block)
      end
    end

    attr_accessor :result
    attr_accessor :formats

    def initialize(*args, &block)
      @result = args.shift if args.first.is_a?(Result)
      @formats = Map.new
    end

    %w( set get has has? [] ).each do |method|
      module_eval <<-__, __FILE__, __LINE__
        def #{ method }(*args, &block)
          data.#{ method }(*args, &block)
        end
      __
    end

    def extend(*args, &block)
      return super if block.nil?
      singleton_class =
        class << self
          self
        end
      singleton_class.module_eval(&block)
    end

    def tag(*args, &block)
      options = Dao.options_for!(args)
      args.push(:div) if args.empty?
      tagname = args.shift
      keys = args

      tag_method = "#{ tagname }_"

      id = options.delete(:id) || id_for(keys)
      klass = class_for(keys, options.delete(:class))
      error = error_for(keys, options.delete(:error))

      tag_options =
        options_for(options, :id => id, :class => klass, :data_error => error)

      value = value_for(keys)
      tag_value = instance_exec(value, &format_for(keys))

      send(tag_method, tag_options){ tag_value }
    end

    include InstanceExec

    DefaultFormat = lambda{|value| value}

    def format_for(keys)
      formats.get(keys) || DefaultFormat
    end

    def format(list_of_keys, &block)
      Array(list_of_keys).each do |keys|
        formats.set(keys, block)
      end
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

    def value_for(keys)
      return nil unless data.has?(keys)
      value = Tagz.escapeHTML(data.get(keys))
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
