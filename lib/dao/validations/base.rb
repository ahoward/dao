module Dao
# objects must have and errors object and a status object to use this mixin
#
  module Validations::Base
    def validations
      @validations ||= Validations.for(self)
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

    def forcing_validity?
      defined?(@forcing_validity) and @forcing_validity
    end

    def valid?(*args)
      if forcing_validity?
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
        status.update(420) if(status.ok? and !errors.empty?)
        errors.empty? and status.ok?
      end
    end

# TODO - consider how to factor out this throw...
#
    def validate!(*args, &block)
      if !args.empty?
        validations.add(*args, &block)
      end
      @forcing_validity = false
      validations.run!
      status.update(420) if(status.ok? and !errors.empty?)
      throw(:result, nil) unless(errors.empty? and status.ok?)
    end

    def validates(*args, &block)
      validations.add(*args, &block)
    end

    def validations
      @validations ||= Validations.for(self)
    end
  end
end
