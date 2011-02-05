module Dao
  class Result < ::Map
    attr_accessor :api
    attr_accessor :interface
    attr_accessor :mode
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
      interface = options[:interface]
      params = options[:params] || Params.new
      mode = options[:mode] || (api ? api.mode : Mode.default)

      path = interface.path if interface

      form = Form.for(self)
      validations = Validations.for(self) 

      self[:path] = path
      self[:status] = status
      self[:mode] = mode
      self[:errors] = errors
      self[:data] = data

      @api = api
      @interface = interface
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

    def mode(*args)
      self[:mode] = Mode.for(*args) unless args.empty?
      self[:mode]
    end
    def mode=(value)
      mode(value)
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
