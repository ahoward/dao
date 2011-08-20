module Dao
  module Validations
    class Validator
      NotBlank = lambda{|value| !value.to_s.strip.empty?} unless defined?(NotBlank)
      Cleared = 'Cleared'.freeze unless defined?(Cleared)

      class << Validator
        def for(*args, &block)
          new(*args, &block)
        end
      end

      attr_accessor :object
      attr_accessor :validations

      def initialize(*args)
        options = Map.options_for!(args)
        @object = args.shift || options[:object]
        @attributes = args.shift || options[:attributes] || :attributes
        @errors = args.shift || options[:errors] || :errors
        @status = args.shift || options[:status] || :status
        @validations = Map.new
      end

      def add(*args, &block)
        options = Map.options_for!(args)
        block = args.pop if args.last.respond_to?(:call)
        block ||= NotBlank
        callback = Callback.new(options, &block)
        validations.set(args => Callback::Chain.new) unless validations.has?(args)
        validations.get(args).add(callback)
        callback
      end

      def run_validations!(*args)
        object = args.first || @object
        run_validations(*args)
      ensure
        object.validated! if object.respond_to?(:validated!) unless $!
      end

      def run_validations(*args)
        object = args.first || @object
        attributes = extract(:attributes, object)
        errors = extract(:errors, object)
        status = extract(:status, object) || Status.default

        attributes.extend(InstanceExec) unless attributes.respond_to?(:instance_exec)

        previous_errors = []
        new_errors = []

        errors.each_message do |keys, message|
          previous_errors.push([keys, message])
        end
        errors.clear!
        status.ok!

        validations.depth_first_each do |keys, chain|
          chain.each do |callback|
            next unless callback and callback.respond_to?(:to_proc)

            number_of_errors = errors.size
            value = attributes.get(keys)
            returned =
              catch(:validation) do
                args = [value, attributes].slice(0, callback.arity)
                attributes.instance_exec(*args, &callback)
              end

            case returned
              when Hash
                map = Map(returned)
                valid = map[:valid]
                message = map[:message]

              when TrueClass, FalseClass
                valid = returned
                message = nil

              else
                any_errors_added = errors.size > number_of_errors
                valid = !any_errors_added
                message = nil
            end

            message ||= callback.options[:message]
            message ||= (value.to_s.strip.empty? ? 'is blank' : 'is invalid')

            unless valid
              new_errors.push([keys, message])
            else
              new_errors.push([keys, Cleared])
            end
          end
        end

        previous_errors.each do |keys, message|
          errors.add(keys, message) unless new_errors.assoc(keys)
        end

        new_errors.each do |keys, value|
          next if value == Cleared
          message = value
          errors.add(keys, message)
        end

        if status.ok? and !errors.empty?
          status.update(412)
        end

        errors
      end

      def extract(attribute, object)
        ivar = "@#{ attribute }"
        value = instance_variable_get(ivar)
        if value
          case value
            when Symbol
              object.send(value)
            else
              value
          end
        else
          object.send(attribute)
        end
      end
    end
  end
end
