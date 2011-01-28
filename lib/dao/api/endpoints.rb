module Dao
  class Api
    class << Api
      def endpoints
        @endpoints ||= Map.new
      end

      def endpoint(path, &block)
        api = self
        path = Path.new(path)

        method =
          module_eval{ 
            define_method(path + '/endpoint', &block)
            instance_method(path + '/endpoint')
          }


        endpoint = Endpoint.new(
          'api' => api,
          'path' => path,
          'method' => method,
          'doc' => docs.pop
        )

        endpoints[path] = endpoint
      end

      def description(string)
        doc(:description => Dao.unindent(string))
      end
      alias_method('desc', 'description')

      def doc(*args)
        docs.push(Map[:description, nil]) if docs.empty?
        doc = docs.last
        options = Dao.options_for!(args)
        if options.empty?
          options[:description] = args.join(' ')
        end
        doc.update(options)
        doc
      end

      def docs
        @docs ||= []
      end

      def index
        index = Map.new
        endpoints.each do |path, endpoint|
          index[path] = endpoint.doc || {'description' => path}
        end
        index
      end
    end

    def call(path = '/index', params = {})
      api = self
      path = Path.new(path)
      endpoint = endpoints[path]
      raise(NameError, path) unless endpoint

      params = parse_params(params, path)

      context = Context.new(
        :api => api,
        :endpoint => endpoint,
        :params => params
      )

      callstack(context) do
        catching(:result){ context.call() }
      end

      context.result
    end

    def index
      self.class.index
    end

    def parse_params(params, path)
      return params if params.is_a?(Params)
      re = %r/^#{ Regexp.escape(path) }/
      params.each do |key, val|
        return Params.parse(path, params) if key =~ re
      end
      return params
    end

    def endpoints
      self.class.endpoints
    end

    def context
      callstack.last
    end

    def result
      context.result
    end

    def status(*args, &block)
      result.status(*args, &block)
    end

    def data
      result.data
    end

    def errors
      result.errors
    end

    def params
      result.params
    end

    def validations
      result.validations
    end

    def validates(*args, &block)
      result.validates(*args, &block)
    end

    def validate
      result.validate
    end

    def valid?
      result.valid?
    end

    def validate!
      result.validate!
    end

    def valid!
      result.valid!
    end

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

    def catching_results(&block)
      catching(:result, &block)
    end

    def catching?
      catching
    end

    def catching_results?
      catching == :result
    end

    def respond_to?(*args)
      super(*args) || super(Path.absolute_path_for(*args))
    end
  end
end
