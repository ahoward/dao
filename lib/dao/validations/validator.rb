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
      attr_accessor :errors
      attr_accessor :status

      def initialize(object)
        @object = object
        @validations = Map.new
        @errors = Errors.new
        @status = Status.new
      end

      fattr(:attributes) do
        attributes =
          catch(:attributes) do
            if @object.respond_to?(:attributes)
              throw :attributes, @object.attributes
            end
            if @object.instance_variable_defined?('@attributes')
              throw :attributes, @object.instance_variable_get('@attributes')
            end
            if @object.is_a?(Map)
              throw :attributes, @object
            end
            if @object.respond_to?(:to_map)
              throw :attributes, Map.new(@object.to_map)
            end
            if @object.is_a?(Hash)
              throw :attributes, Map.new(@object)
            end
            if @object.respond_to?(:to_hash)
              throw :attributes, Map.new(@object.to_hash)
            end
            raise ArgumentError.new("found no attributes on #{ @object.inspect }(#{ @object.class.name })")
          end

        case attributes
          when Map
            attributes
          when Hash
            Map.new(attributes)
          else
            raise(ArgumentError.new("#{ attributes.inspect } (#{ attributes.class })"))
        end
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
      alias_method('validates', 'add')

      def run_validations!(*args)
        run_validations(*args)
      ensure
        validated!
      end

      def validations_search_path
        @validations_search_path ||= (
          list = [
            object,
            object.class.ancestors.map{|ancestor| ancestor.respond_to?(:validator) ? ancestor : nil}
          ]
          list.flatten!
          list.compact!
          list.reverse!
          list
        )
      end

      def validations_list
        validations_search_path.map{|object| object.validator.validations}
      end

      def run_validations(*args)
        object = args.first || @object

        attributes.extend(InstanceExec) unless attributes.respond_to?(:instance_exec)

        previous_errors = []
        new_errors = []

        errors.each_message do |keys, message|
          previous_errors.push([keys, message])
        end
        errors.clear!
        status.ok!

        list = validations_list

        list.each do |validations|
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

      def validated?
        @validated = false unless defined?(@validated)
        @validated
      end

      def validated!(boolean = true)
        @validated = !!boolean
      end

      def validate
        run_validations
      end

      def validate!
        raise Error.new("#{ object.class.name } is invalid!") unless valid?
        object
      end

      def valid!
        @forcing_validity = true
      end

      def forcing_validity?
        defined?(@forcing_validity) and @forcing_validity
      end

      def forcing_validity!(boolean = true)
        @forcing_validity = !!boolean
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

      def reset
        errors.clear!
        status.update(:ok)
        forcing_validity!(false)
        validated!(false)
        self
      end
    end
  end

  Validator = Validations::Validator
end
