module Dao
  class Context
    Attrs = %w( api route path interface args status errors params result data form validations )

    Attrs.each{|a| attr_accessor(a)}

    def Context.attrs
      Attrs
    end

    def Context.for(api, route, path, interface, params, *args)
    # setup
    #
      options = Dao.options_for!(args)

      parsed_params = Dao.parse(path, params, options)

      result = Result.new(:mode => api.mode)
      params = result.params
      params.update(parsed_params)

      args =
        if interface.arity < 1
          [params, result]
        else
          [params, result].slice(0, interface.arity)
        end

    # build the context
    #
      context = new
      context.api = api
      context.interface = interface
      context.route = route
      context.path = path
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
      result.route = context.route
      result.path = context.path
      result.status = context.status
      result.errors = context.errors

      params.route = context.route
      params.path = context.path
      params.status = context.status
      params.errors = context.errors

      context
    end

    include InstanceExec

    def call
      api.instance_exec(*args, &interface)
    end
  end
end
