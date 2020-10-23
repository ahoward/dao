module Dao
  module Coerce
  ## built-in
  #
    require 'uri'
    require 'time'
    require 'date'
    require 'pathname'
    require 'chronic'

  ## version
  #
    Coerce::Version = '0.0.8'

    def self.version
      Coerce::Version
    end

  ## dependencies
  #
    def self.dependencies
      {
        'chronic'   =>  [ 'chronic'   , '>= 0.6.2' ]
      }
    end

    begin
      require 'rubygems'
    rescue LoadError
      nil
    end

    if defined?(gem)
      self.dependencies.each do |lib, dependency|
        gem(*dependency)
        require(lib)
      end
    end

  ##
  #
    def self.export m
      module_function m
      public m
    end

    List = []

    def self.coerce m, &b
      define_method m, &b
      export m
      List << m.to_s
    end

    coerce :boolean do |obj|
      case obj.to_s
        when %r/^(true|t|1|yes|y|on)$/i
          true
        when %r/^(false|f|0|no|n|off)$/i
          false
        else
          !!obj
      end
    end

    coerce :integer do |obj|
      Float(obj).to_i
    end

    coerce :float do |obj|
      Float obj
    end

    coerce :number do |obj|
      Float obj rescue Integer obj
    end

    coerce :string do |obj|
      String obj
    end

    coerce :symbol do |obj|
      String(obj).to_sym
    end

    coerce :uri do |obj|
      ::URI.parse obj.to_s
    end

    coerce :url do |obj|
      ::URI.parse(obj.to_s).to_s
    end

    coerce :time do |obj|
      ::Chronic.parse(obj.to_s)
    end

    coerce :date do |obj|
      begin
        ::Date.parse(::Chronic.parse(obj.to_s).to_s)
      rescue
        ::Date.parse(obj.to_s)
      end
    end

    coerce :pathname do |obj|
      Pathname.new(obj.to_s)
    end

    coerce :path do |obj|
      File.expand_path(obj.to_s)
    end

    coerce :input do |obj|
      case obj.to_s
        when '-'
          io = STDIN.dup
          io.fattr(:path){ '/dev/stdin' }
          io
        else
          io = open(obj.to_s, 'r+')
          at_exit{ io.close }
          io
      end
    end

    coerce :output do |obj|
      case obj.to_s
        when '-'
          io = STDOUT.dup
          io.fattr(:path){ '/dev/stdout' }
          io
        else
          io = open(obj.to_s, 'w+')
          at_exit{ io.close }
          io
      end
    end

    coerce :slug do |obj|
      string = [obj].flatten.compact.join('-')
      words = string.to_s.scan(%r/\w+/)
      words.map!{|word| word.gsub %r/[^0-9a-zA-Z_-]/, ''}
      words.delete_if{|word| word.nil? or word.strip.empty?}
      String(words.join('-').downcase)
    end

    coerce :list do |*objs|
      [*objs].flatten.join(',').split(/[\n,]/).map{|item| item.strip}.delete_if{|item| item.strip.empty?}
    end

    coerce :array do |*objs|
      [*objs].flatten.join(',').split(/[\n,]/).map{|item| item.strip}.delete_if{|item| item.strip.empty?}
    end

    coerce :hash do |*objs|
      list = Coerce.list(*objs)
      hash = Hash.new
      list.each do |pair|
        k, v = pair.split(/[=:]+/, 2)
        key = k.to_s.strip
        val = v.to_s.strip
        hash[key] = val
      end
      hash
    end

  # add list_of_xxx methods
  #
    List.dup.each do |type|
      next if type.to_s =~ %r/list/ 
      %W" list_of_#{ type } list_of_#{ type }s ".each do |m|
        define_method m do |*objs|
          list(*objs).map{|obj| send type, obj}
        end
        export m 
        List << m
      end
    end

  # add list_of_xxx_from_file
  #
    List.dup.each do |type|
      next if type.to_s =~ %r/list/ 
      %W" list_of_#{ type }_from_file list_of_#{ type }s_from_file ".each do |m|
        define_method m do |*args|
          buf = nil
          if args.size == 1 and args.first.respond_to?(:read)
            buf = args.first.read
          else
            open(*args){|io| buf = io.read}
          end
          send(m.sub(/_from_file/, ''), buf)
        end
        export m
        List << m
      end
    end

    def self.[] sym
      prefix = sym.to_s.downcase.to_sym
      candidates = List.select{|m| m =~ %r/^#{ prefix }/i}
      m = candidates.shift
      raise ArgumentError, "unsupported coercion: #{ sym.inspect } (#{ List.join ',' })" unless
        m
      raise ArgumentError, "ambiguous coercion: #{ sym.inspect } (#{ List.join ',' })" unless
        candidates.empty? or m.to_s == sym.to_s
      lambda{|obj| method(m).call obj}
    end
  end
end
