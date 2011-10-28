module Dao
  class Context
    Attrs = %w(
      api path route endpoint
      params validator errors status form
      result
      data
      args
    )

    Attrs.each{|a| attr_accessor(a)}

    def Context.attrs
      Attrs
    end

    def Context.for(*args, &block)
      new(*args, &block)
    end

    def initialize(api, path, route, endpoint, params, *args)
      @api = api
      @path = path
      @route = route
      @endpoint = endpoint

      @params = Params.new
      @params.update(params)
      @params.path = @path
      @params.route = @route
      @form = @params.form

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

      @data = @result.data

      @args = @endpoint.arity < 1 ? [@params, @result] : [@params, @result].slice(0, @endpoint.arity)
    end

    def call
      @api.instance_exec(*@args, &@endpoint)
    end
  end
end
