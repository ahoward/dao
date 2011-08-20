module Dao
  module Validations
    class Error < Dao::Error; end

    Dao.load('validations/validator.rb')
    Dao.load('validations/callback.rb')
    Dao.load('validations/common.rb')

    ClassMethods = proc do
      def validator
        @validator ||= Validator.new(self)
      end

      def validator=(validator)
        @validator = validator
      end

      def validations
        validator.validations
      end

      def validates(*args, &block)
        validator.add(*args, &block)
      end
    end

    InstanceMethods = proc do
      def validator
        defined?(@validator) ? @validator : self.class.validator
      end

      def validator=(validator)
        @validator = validator
      end

      def validations
        validator.validations
      end

      def validates(*args, &block)
        validator.add(*args, &block)
      end

      def validated?
        @validated = false unless defined?(@validated)
        @validated
      end

      def validated!
        @validated = true
      end

      def validate
        run_validations!
      end

      def validate!
        run_validations!
        raise Error.new("#{ self.class.name } is invalid!") unless valid?
        self
      end

      def run_validations!
        validator.run_validations!(self)
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
          options = Map.options_for!(args)
          validate #if(options[:validate] or !validated?)
          errors.empty? and status.ok?
        end
      end

      def errors
        @errors ||= Errors.new(self)
      end

      def status
        @status ||= Status.default
      end
    end

    def Validations.included(other)
      other.send(:instance_eval, &ClassMethods)
      other.send(:class_eval, &InstanceMethods)
      other.send(:include, Common)
      other.send(:extend, Common)
      super
    end
  end
end
