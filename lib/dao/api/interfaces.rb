module Dao
  class Api
  # class methods
  #
    class << Api
      def unload!
        state.clear
      end

      def state
        @state ||= {
          :interfaces => Map.new,
          :blocks => {},
          :README => [],
          :docs => []
        }
      end

      def call(*args, &block)
        options = Dao.options_for!(args)
        path = Path.new(args.shift || raise(ArgumentError, "no path!"))

        api = self

        route = routes.add(path) if Route.like?(path)

        interface =
          if options.key?(:alias)
            aliased_path = Path.new(options[:alias])
            interfaces[aliased_path] || raise(ArgumentError, "no such path #{ aliased_path }!")
          else
            Interface.new({
              'api' => api,
              'path' => path,
              'route' => route,
              'block' => block,
              'doc' => docs.pop
            })
          end

        interfaces[path] = interface
      end
      alias_method('interface', 'call')

      def interfaces
        state[:interfaces]
      end

      def doc(*args)
        docs.push(Map(:doc => nil)) if docs.empty?
        doc = docs.last

        options = Dao.options_for!(args)
        options[:doc] = lines_for(*args) if options.empty?

        doc.update(options)
        doc
      end

      def description(*args)
        doc(:doc => lines_for(*args))
      end

      alias_method('desc', 'description')

      def docs
        state[:docs]
      end

      def readme(*args)
        if args.empty?
          state[:README]
        else
          state[:README] = lines_for(args)
        end
      end
      alias_method('README', 'readme')

      def lines_for(*args)
        Dao.unindent(args.flatten.compact.join("\n")).split(/\n/)
      end

      def readme=(readme)
        self.readme = readme.to_s
      end

      def index
        index = Map.new
        index[:README] = readme
        interfaces.sort.each do |path, interface|
          index[path] = interface.doc || {'description' => ''}
        end
        index
      end
    end

# instance methods
#


  # call support 
  #
    def call(path = '/index', params = {}, options = {})
      api = self
      path = Path.new(path)
      interface = interfaces[path]  ### interfaces.by_path(path)
      route = nil

      unless interface
        route = route_for(path)
        interface = interfaces[route]
      end

      unless interface
        return index if path == '/index'
        raise(NameError, "NO SUCH INTERFACE: #{ path }")
      end

      if route
        params.update(route.params_for(path))
        path = route.path_for(params)
      else
        if Route.like?(path)
          route = Route.new(path)
          path = route.path_for(params)
        else
          route = path
        end
      end

      context = Context.for(api, route, path, interface, params, options)

      callstack(context) do
        catching(:result) do
          context.call()
        end
      end

      context.result
    end

  # will an interface route to a interface?
  #
    def route?(path)
      path = Path.new(path)
      interface = interfaces[path]
      route = nil

      unless interface
        route = route_for(path)
        interface = interfaces[route]
      end

      interface
    end


  # lookup a route
  #
    def route_for(*args)
      self.class.routes.match(*args)
    end

  # context support
  #
    def callstack(context = nil, &block)
      @callstack ||= []

      if block and context
        begin
          @callstack.push(context)
          return block.call()
        ensure
          @callstack.pop
        end
      else
        @callstack
      end
    end

    def context
      callstack.last || raise('no context!')
    end

    def context?
      !!callstack.last
    end

    def catching(label = :result, &block)
      @catching ||= []

      if block
        begin
          @catching.push(label)
          catch(label, &block)
        ensure
          @catching.pop
        end
      else
        @catching.last
      end
    end

    def return!(*value)
      throw(:result, *value)
    end

    def catching_results(&block)
      catching(:result, &block)
    end

    def catching?
      catching
    end

    def catching_results?
      catching == :result
    end

  # delgate some methods to the context
  #
    Context.attrs.each do |method|
      module_eval <<-__, __FILE__, __LINE__
        def #{ method }(*args)
          context.send(#{ method.inspect }, *args)
        end
      __
    end

    def status(*args)
      context.status.update(*args) unless args.empty?
      context.status
    end
    def status!(*args)
      status.update(*args)
      return!
    end

    def data(*args)
      context.data.replace(*args) unless args.empty?
      context.data
    end
    def data!(*args)
      data(*args)
      valid!
    end

    def params!(*args)
      params.replace(*args)
      valid!
    end

    def error!
      result.error!
    end

  # delegate some methods to the params
  #
    Validations::Mixin.list.each do |method|
      module_eval <<-__, __FILE__, __LINE__
        def #{ method }(*args)
          params.send(#{ method.inspect }, *args)
        end
      __
    end

  # misc
  #
    def index
      self.class.index
    end

    def interfaces
      self.class.interfaces
    end

    def respond_to?(*args)
      super(*args) || super(Path.absolute_path_for(*args))
    end

  # immediate parameter parsing support
  #
    def parameter(*args, &block)
      options = Map.options_for!(args)

      keys = args + Array(options[:keys]) + Array(options[:or])

      raise(ArgumentError, 'no keys') if keys.empty?

      blank = Object.new.freeze
      value = blank

      keys.each do |key|
        if params.has?(key)
          value = params.get(key)
          break unless value.to_s.strip.empty?
        end
      end

      if value == blank
        message =
          case options[:error]
            when nil, false
              nil
            when true
              which = keys.map{|key| Array(key).join('.')}.join(' or ')
              "#{ which } (parameter is blank)"
            else
              message = options[:error].to_s
          end
        errors.add(message) if message

        status(options[:status]) if options[:status]
        return! if options[:return!]
      end

      value == blank ? nil : value
    end
    alias_method('param', 'parameter')

    def parameter!(*args, &block)
      options = args.last.is_a?(Hash) ? Map.for(args.pop) : Map.new
      args.push(options)
      options[:error] = true unless options.has_key?(:error)
      options[:return!] = true unless options.has_key?(:return!)
      options[:status] = 412 unless options.has_key?(:status)
      parameter(*args, &block)
    end
    alias_method('param!', 'parameter!')
  end
end
