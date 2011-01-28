module Dao
  class Result < ::Map
    attr_accessor :api
    attr_accessor :endpoint
    attr_accessor :params
    attr_accessor :validations
    attr_accessor :form

    def Result.for(*args, &block)
      new(*args, &block)
    end

    def initialize(*args, &block)
      options = Dao.options_for!(args)
      args.push('/dao') if args.empty?

      path = Path.for(*args)
      status = Status.ok
      errors = Errors.new
      data = Data.new

      api = options[:api]
      endpoint = options[:endpoint]
      params = options[:params] || Params.new

      path = endpoint.path if endpoint

      form = Form.for(self)
      validations = Validations.for(self) 

      self[:path] = path
      self[:status] = status
      self[:errors] = errors
      self[:data] = data

      @api = api
      @endpoint = endpoint
      @params = params
      @form = form
      @validations = validations
    end

    def path
      self[:path]
    end

    def status(*args)
      self[:status] = Status.for(*args) unless args.empty?
      self[:status]
    end
    def status=(value)
      status(value)
    end

    def errors
      self[:errors]
    end

    def data
      self[:data]
    end

    def validates(*args, &block)
      validations.add(*args, &block)
    end

    def validate(*args, &block)
      if !args.empty?
        validates(*args, &block)
      else
        validations.run
        #status(420) if(status.ok? and !errors.empty?)
        errors.empty? and status.ok?
      end
    end

    def valid?
      validate
    end

    def validate!
      validations.run!
      #status(420) if(status.ok? and !errors.empty?)
      throw(:result, nil) unless(errors.empty? and status.ok?)
    end
  end
end
