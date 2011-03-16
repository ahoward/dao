module Dao
  class Result < ::Map
    include Dao::InstanceExec

    attr_accessor :api
    attr_accessor :interface
    attr_accessor :mode
    attr_accessor :params
    attr_accessor :validations
    attr_accessor :presenter
    attr_accessor :form
    attr_accessor :forcing_validity

    def Result.for(*args, &block)
      new(*args, &block)
    end

    def initialize(*args, &block)
      options = Dao.options_for!(args)
      args.push('/dao') if args.empty?

      path_args = args.select{|arg| arg.is_a?(String) or args.is_a?(Symbol)}
      data_args = args.select{|arg| arg.is_a?(Hash)}
      data_args += [options[:data]] if options.has_key?(:data)

      path = Path.for(*path_args)
      status = Status.ok
      errors = Errors.new
      data = Data.new

      data_args.each do |data_arg|
        data.update(data_arg)
      end

      api = options[:api]
      interface = options[:interface]
      params = options[:params] || Params.new
      mode = options[:mode] || (api ? api.mode : Mode.default)

      params.result = self
      path = interface.path if interface

      form = Form.for(self)
      validations = Validations.for(self) 
      presenter = Presenter.for(self) 

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
      @presenter = presenter
      @forcing_validity = false
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

    def is_valid=(boolean)
      @is_valid = !!boolean 
    end

    def is_valid(*bool)
      @is_valid ||= nil
      @is_valid = !!bool.first unless bool.empty?
      @is_valid
    end

    def valid!
      @forcing_validity = true
    end

    def valid?(*args)
      if @forcing_validity
        true
      else
        options = Dao.options_for!(args)
        validate unless validations.ran?
        validate if options[:validate]
        errors.empty? and status.ok?
      end
    end

    def validate(*args, &block)
      if !args.empty?
        validations.add(*args, &block)
      else
        validations.run
        status(420) if(status.ok? and !errors.empty?)
        errors.empty? and status.ok?
      end
    end

    def validate!(*args, &block)
      if !args.empty?
        validations.add(*args, &block)
      end
      @forcing_validity = false
      validations.run!
      status(420) if(status.ok? and !errors.empty?)
      throw(:result, nil) unless(errors.empty? and status.ok?)
    end

    def validates(*args, &block)
      validations.add(*args, &block)
    end

    def error!
      raise Dao::Error::Result.for(self)
    end

    def tag(*args, &block)
      presenter.tag(*args, &block)
    end

    def inspect
      ::JSON.pretty_generate(self, :max_nesting => 0)
    end
  end
end
