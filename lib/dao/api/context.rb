# -*- encoding : utf-8 -*-
module Dao
  class Context
    Attrs = %w(
      api path route endpoint
      params validator errors status form
      result
      data
      session
      args
    )

    Attrs.each{|a| attr_accessor(a)}

    def Context.attrs
      Attrs
    end

    def Context.for(*args, &block)
      if args.size == 1 && args.first.is_a?(Context) && block.nil?
        return args.first
      end

      new(*args, &block)
    end

    def initialize(*args)
    #
      options = Map.extract_options!(args)

      api = args.shift || options[:api] || Api.new
      path = args.shift || options[:path] || Path.default
      route = args.shift || options[:route] || Route.default
      params = args.shift || options[:params] || Hash.new
      session = args.shift || options[:session] || Hash.new
      endpoint = args.shift || options[:endpoint]

    #
      @api = api
      @path = path
      @route = route

      @params = Params.new
      @params.update(params)
      @params.path = @path
      @params.route = @route
      @form = @params.form

      @session = Map.for(session)

      @endpoint = endpoint

    #
      @validator = Validator.new(@params)
      @validator.validations_search_path.unshift(@api.class)

      @validations = @validator.validations

      @params.validator = @validator
      @errors = @validator.errors
      @status = @validator.status

      @result = Result.new
      @result.path = @path
      @result.route = @route
      @result.status = @status
      @result.mode = @api.mode
      @result.params = @params
      @result.errors = @params.errors
      @result.session = @session

      @data = @result.data

      if @endpoint
        @argv =
          if @endpoint.arity < 1
            [@params, @result]
          else
            [@params, @result].slice(0, @endpoint.arity)
          end
      else
        @argv = []
      end
    end

    def callable?
      !!@endpoint
    end

    def call
      @api.instance_exec(*@argv, &@endpoint) if callable?
    end
  end
end
