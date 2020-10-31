# -*- encoding : utf-8 -*-
module Dao
  class Api
  # class methods
  #
    class << Api
      def unload!
        state.clear
      end

      def state
        @state ||= Map.new({
          :endpoints => Map.new,
          :endpoint => nil,
          :blocks => {},
          :README => [],
          :docs => [],
          :paths => [],
        })
      end

      def call(*args, &block)
        options = Dao.options_for!(args)
        path = Path.new(args.shift || paths.pop || raise(ArgumentError, "no path!"))

        api = self

        route = routes.add(path) if Route.like?(path)

        doc = args.shift || options[:doc]
        self.doc(doc) if doc

        endpoint =
          if options.key?(:alias)
            aliased_path = Path.new(options[:alias])
            endpoints[aliased_path] || raise(ArgumentError, "no such path #{ aliased_path }!")
          else
            Endpoint.new({
              'api' => api,
              'path' => path,
              'route' => route,
              'block' => block,
              'doc' => docs.pop
            })
          end

        endpoints[path] = endpoint
      end

      def endpoint(options = {}, &block)
      #
        if Api.state.endpoint
          endpoint = Api.state.endpoint
        else
          options = Map.for(options)
          endpoint = Endpoint.new
          endpoint.api = self
        end

      #
        endpoint.instance_eval(&block)

      #
        path = Path.new(endpoint.path || options[:path] || paths.pop || raise(ArgumentError, "no path!"))
        endpoint.path = path

        if endpoint.route
          routes.push(endpoint.route) unless routes.include?(endpoint.route)
        else
          if Route.like?(endpoint.path)
            route = routes.add(endpoint.path)
            endpoint.route = route
          end
        end

      #
        endpoints[endpoint.path] = endpoint
      end

      def load_endpoint_directory!(directory, options = {})
        path_d = Pathname.new(directory).realpath

        glob = "#{ path_d }/**/**.rb"

        loaded = []

        entries = Dir.glob(glob).to_a.sort

        entries.each do |entry|
          next unless test(?f, entry)
          file = entry

          path_f = Pathname.new(file).realpath

          path_r = path_f.relative_path_from(path_d)

          base, _ext = path_r.to_s.split('.', 2)

          parts = base.split('/')

          parts.map!{|part| part =~ /\A_/ ? part.sub(/_/, ':') : part}

          path = parts.join('/')

          endpoint = load_endpoint_file!(file, :path => path)
          
          loaded << endpoint
        end

        loaded
      end

      def load_endpoint_file!(file, options = {})
        path = Path.new(options[:path] || paths.pop || raise(ArgumentError, "no path!"))

        endpoint = Endpoint.new
        endpoint.api = self
        endpoint.path = path

        previous = Api.state.endpoint
        Api.state.endpoint = endpoint 

        begin
          ::Kernel.load(file)
        ensure
          Api.state.endpoint = previous
        end

        endpoint
      end

      def endpoints
        state[:endpoints]
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

      def paths
        state[:paths]
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
        endpoints.each do |path, endpoint|
          index[path] = endpoint.doc || {'description' => ''}
        end
        index
      end
    end

# instance methods
#


  # call support 
  #
    def call(path = '/index', params = {}, session = {})
    #
      api = self

      path = Path.new(path)

      params = Dao.params_for(params)

      session = Map.for(session)

    #
      endpoint = endpoints[path]  ### endpoints.by_path(path)
      route = nil

      unless endpoint
        route = route_for(path)
        endpoint = endpoints[route]
      end

      unless endpoint
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

    #
      context =
        Context.for(
          api, 
          :path     => path,
          :route    => route,
          :params   => params,
          :session  => session,
          :endpoint => endpoint
        )

      callstack(context) do
        catching(:result) do
          context.call()
        end
      end

      context.result
    end

  # will an endpoint route to a endpoint?
  #
    def route?(path)
      path = Path.new(path)
      endpoint = endpoints[path]
      route = nil

      unless endpoint
        route = route_for(path)
        endpoint = endpoints[route]
      end

      endpoint
    end


  # lookup a route
  #
    def route_for(*args)
      self.class.routes.match(*args)
    end

  # context stack support
  #
    def callstack(context = nil, &block)
      @callstack ||= [default_context]

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

    def default_context
      @default_context ||= Context.for(self)
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
        rescue Dao::Validations::Error
          nil
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
    def api
      self
    end

    def callable?
      context.callable?
    end

    def path
      context.path
    end

    def route
      context.route
    end

    def endpoint
      context.endpoint
    end

    def helpers
      endpoint.helpers
    end

    def h
      endpoint.h
    end

    def form
      context.form
    end

    def params
      context.params
    end

    def result
      context.result
    end

    def status(*args)
      context.status.update(*args) unless args.empty?
      context.status
    end
    def status=(*args)
      context.status.update(*args)
      context.status
    end
    def status!(*args)
      status.update(*args)
      return!
    end

    def session(*args)
      context.session.replace(*args) unless args.empty?
      context.session
    end
    def session=(*args)
      context.session.replace(*args)
      context.session
    end
    def session!(*args)
      session(*args)
      return!
    end

    def data(*args)
      context.data.replace(*args) unless args.empty?
      context.data
    end
    def data=(*args)
      context.data.replace(*args)
      context.data
    end
    def data!(*args)
      data(*args)
      return!
    end

  # validations are also 'context sensitive'
  #
    def validator
      context.validator
    end

    include Dao::Validations


  # misc
  #
    def index
      self.class.index
    end

    def endpoints
      self.class.endpoints
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
