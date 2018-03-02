# -*- encoding : utf-8 -*-
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
    s.each_line do |line|
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

  def current
    Current
  end

  def current_controller(*args)
    Current.controller = args.first unless args.empty?
    Current.controller
  end
  alias_method('controller', 'current_controller')

  def current_controller=(controller)
    Current.controller = controller
  end
  alias_method('controller=', 'current_controller=')

  def mock_controller
    Current.mock_controller
  end

  %w( request response session ).each do |attr|
    module_eval <<-__, __FILE__, __LINE__
      def current_#{ attr }
        current_controller.instance_eval{ #{ attr } }
      end
    __
  end

  %w( current_user effective_user real_user ).each do |attr|
    module_eval <<-__, __FILE__, __LINE__
      def #{ attr }
        current_controller.instance_eval{ #{ attr } }
      end
    __
  end

  def root
    if defined?(Rails.root) and Rails.root
      Rails.root
    else
      '.'
    end
  end

  def normalize_parameters(params)
    dao = (params.delete('dao') || {}).merge(params.delete(:dao) || {})

    unless dao.empty?
      dao.each do |key, paths_and_values|
        next if paths_and_values.blank?
        map = Map.for(params[key])

        paths_and_values.each do |path, value|
          keys = keys_for(path)
          if map.has?(keys)
            inc_keys!(keys)
          end
          map.set(keys => value)
        end

        params[key] = map
      end

      params['dao'] = dao
    end

    params
  end

  def keys_for(*keys)
    keys = keys.join('.').scan(/[^\,\.\s]+/iomx)
    
    keys.map do |key|
      digity, stringy, digits = %r/^(~)?(\d+)$/iomx.match(key).to_a

      digity ? stringy ? String(digits) : Integer(digits) : key
    end
  end
  alias_method(:key_for, :keys_for)

  def inc_keys!(keys)
    last_number_index = nil

    keys.each_with_index do |k, i|
      if k.is_a?(Numeric)
        last_number_index = i
      end
    end

    if last_number_index
      keys[last_number_index] = keys[last_number_index] + 1
    end

    keys
  end

  def render_json(object, options = {})
    options = options.to_options!
    controller = options[:controller] || Dao.current_controller

    controller.instance_eval do
      json = Dao.json_for(object)

      status = object.status rescue (options[:status] || 200)
      status = status.code if status.respond_to?(:code)

      respond_to do |wants|
        wants.json{ render :json => json, :status => status }
        wants.html{ render :text => json, :status => status, :content_type => 'text/plain' }
        wants.xml{ render :text => 'no soup for you!', :status => 403 }
      end
    end
  end

  def json_for(object, options = {})
    object = object.as_json if object.respond_to?(:as_json)

    options = options.empty? ? Map.for(options) : options
    options[:pretty] = json_pretty?  unless options.has_key?(:pretty)

    begin
      MultiJson.dump(object, options)
    rescue Object => _
      YAML.load( object.to_yaml ).to_json
    end
  end

  def json_pretty?
    @json_pretty ||= (defined?(Rails) ? !Rails.env.production? : true)
  end

  def call(object, method, *args, &block)
    args = Dao.args_for_arity(args, object.method(method).arity)
    object.send(method, *args, &block)
  end

  def args_for_arity(args, arity)
    arity = Integer(arity.respond_to?(:arity) ? arity.arity : arity)
    arity < 0 ? args.dup : args.slice(0, arity)
  end

  def tree_walk(node, *path, &block)
    iterator = Array === node ? :each_with_index : :each

    node.send(iterator) do |key, val|
      key, val = val, key if Array === node
      path.push(key)
      begin
        caught =
          catch(:tree_walk) do
            block.call(path, val)
            nil
          end
        next if caught==:next_sibling

        case val
          when Hash, Array
            tree_walk(val, *path, &block)
        end
      ensure
        path.pop
      end
    end
  end


  {
    'ffi-uuid'  => proc{|*args| FFI::UUID.generate_time.to_s},
    'uuidtools' => proc{|*args| UUIDTools::UUID.timestamp_create.to_s},
    'uuid'      => proc{|*args| UUID.generate.to_s},
  }.each do |lib, implementation|
    begin
      require(lib)
      define_method(:uuid, &implementation)
      break
    rescue LoadError
      nil
    end
  end
  abort 'no suitable uuid generation library detected' unless method_defined?(:uuid)

  def ensure_interface!(object, *interface)
    interface.flatten.compact.each do |method|
      raise(NotImplementedError, "#{ object.class.name }##{ method }") unless object.respond_to?(method)
    end
  end
end
