module Dao
  def map_for(*args, &block)
    Map.for(*args, &block)
  end
  alias_method(:map, :map_for)
  alias_method(:hash, :map_for)

  def options_for!(args)
    Map.options_for!(args)
  end

  def options_for(args)
    Map.options_for(args)
  end

  def db(*args, &block)
    if args.empty? and block.nil?
      Db.instance
    else
      method = args.shift
      Db.instance.send(method, *args, &block)
    end
  end

  %w( to_dao as_dao ).each do |method|

    module_eval <<-__, __FILE__, __LINE__ - 1

      def #{ method }(object, *args, &block)
        case object
          when Array
            object.map{|element| Dao.#{ method }(element, *args, &block)}

          else
            if object.respond_to?(:#{ method })
              object.send(:#{ method }, *args, &block)
            else
              if object.respond_to?(:to_hash)
                object.to_hash
              else
                object
              end
            end
        end
      end

    __
  end


  def unindent!(s)
    margin = nil
    s.each do |line|
      next if line =~ %r/^\s*$/
      margin = line[%r/^\s*/] and break
    end
    s.gsub! %r/^#{ margin }/, "" if margin
    margin ? s : nil
  end

  def unindent(s)
    s = "#{ s }"
    unindent!(s)
    s
  end

  def name_for(path, *keys)
    Form.name_for(path, *keys)
  end
end
