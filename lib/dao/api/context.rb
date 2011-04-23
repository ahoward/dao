module Dao
  class Context
    Attrs = %w( api path interface method args status errors params result data form validations )

    Attrs.each{|a| attr_accessor(a)}

    def Context.attrs
      Attrs
    end

    def Context.for(api, interface, params, *args)
    # setup
    #
      options = Dao.options_for!(args)

      path = interface.path
      parsed_params = Dao.parse(path, params, options)

      result = Result.new(:mode => api.mode)
      params = result.params
      params.update(parsed_params)

      method = interface.method.bind(api)
      args = [params, result].slice(0, method.arity)

    # build the context
    #
      context = new
      context.api = api
      context.interface = interface
      context.path = path
      context.method = method
      context.args = args
      context.status = Status.default
      context.errors = Errors.new

      context.result = result
      context.data = result.data

      context.params = params
      context.form = params.form
      context.validations = params.validations

    # wire up shared state
    #
      result.path = context.path
      result.status = context.status
      result.errors = context.errors

      params.path = context.path
      params.status = context.status
      params.errors = context.errors

      context
    end

    def call
      method.call(*args)
    end
  end
end
