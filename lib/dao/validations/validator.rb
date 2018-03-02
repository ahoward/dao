# -*- encoding : utf-8 -*-
module Dao
  module Validations
    class Validator
      NotBlank = proc{|value| !value.to_s.strip.empty?} unless defined?(NotBlank)
      Cleared = 'Cleared'.freeze unless defined?(Cleared)

      include Common

      def validator
        self
      end

      def validator=(validator)
        raise NotImplementedError
      end

      class << Validator
        def mixin(*args, &block)
          new(*args, &block).tap do |validator|
            validator.mixin = true
          end
        end
      end

      attr_accessor :object
      attr_accessor :options
      attr_accessor :validations
      attr_accessor :errors
      attr_accessor :status

      fattr(:attributes){ extract_attributes! }
      alias_method(:data, :attributes)

      fattr(:mixin){ false }

      def initialize(*args, &block)
        @object = args.shift
        @options = Map.options_for(args)

        if args.size == 1 and @object and @object.is_a?(Hash)
          object_keys = @object.keys.map{|key| key.to_s}
          option_keys = %w( object validations errors status )

          object_is_options = !object_keys.empty? && (object_keys - option_keys).empty?

          if object_is_options
            @options = Map.for(@object)
            @object = nil
          end
        end
  
        @object ||= (@options[:object] || Map.new)
        @validations ||= (@options[:validations] || Map.new)
        @errors ||= (@options[:errors] || Errors.new)
        @status ||= (@options[:status] || Status.new)

        unless @object.respond_to?(:validator)
          @object.send(:extend, Dao::Validations)
          @object.validator = self
        end

        @errors.object = @object

        #@object.extend(InstanceExec) unless @object.respond_to?(:instance_exec)
      end

      def extract_attributes!(object = @object)
        attributes =
          case
            when object.respond_to?(:attributes)
              object.attributes
            when object.instance_variable_defined?('@attributes')
              object.instance_variable_get('@attributes')
            when object.is_a?(Map)
              object
            when object.respond_to?(:to_map)
              Map.new(object.to_map)
            when object.is_a?(Hash)
              Map.new(object)
            when object.respond_to?(:to_hash)
              Map.new(object.to_hash)
            else
              raise ArgumentError.new("found no attributes on #{ object.inspect }(#{ object.class.name })")
          end

        @attributes =
          case attributes
            when Map
              attributes
            when Hash
              Map.new(attributes)
            else
              raise(ArgumentError.new("#{ attributes.inspect } (#{ attributes.class })"))
          end

        @attributes
      end

      def validates(*args, &block)
        block = args.pop if args.last.respond_to?(:call)
        block ||= NotBlank
        callback = Callback.new(options, &block)
        Map.options_for!(args)
        key = key_for(args)
        validations = stack.validations.last || self.validations
        validations[key] ||= Callback::Chain.new
        validations[key].add(callback)
        callback
      end
      alias_method('add', 'validates')

      def validates_each(*args, &block)
        options = Map.options_for!(args)
        key_for(args)

        args.push(options)

        validates(*args) do |list|
          Array(list).each_with_index do |item, index|
            args = Dao.args_for_arity([item], block.arity)
            validates(index, &block)
          end
          true
        end
      end

      def stack
        @stack ||= Map[:validations, [], :prefixes, []]
      end

      def prefixing(*prefix, &block)
        prefix = Array(prefix).flatten.compact
        push_prefix(prefix)
        begin
          block.call(*[prefix].slice(0, block.arity))
        ensure
          pop_prefix
        end
      end
      alias_method('validating', 'prefixing')

      def push_prefix(prefix)
        prefix = Array(prefix).flatten.compact
        stack.prefixes.push(prefix)
      end

      def pop_prefix
        stack.prefixes.pop
      end

      def prefix
        stack.prefixes.flatten.compact
      end

      def key_for(*key)
        prefix + Array(key).flatten.compact
      end

      def get(key)
        attributes.get(key_for(key))
      end

      def set(key, val)
        attributes.set(key_for(key), val)
      end

      def has(key)
        attributes.has(key_for(key))
      end

      alias_method 'has?', 'has'

      def validations_search_path
        @validations_search_path ||= (
          if mixin?
            list = [
              object.respond_to?(:validator) ? object : nil,
              object.class.ancestors.map{|ancestor| ancestor.respond_to?(:validator) ? ancestor : nil}
            ]
            list.flatten!
            list.compact!
            list.reverse!
            list.uniq!
            list
          else
            [self]
          end
        )
      end

      def validations_list
        validations_search_path.map{|object| object.validator.validations}.uniq
      end

      def run_validations(list = validations_list)
        loop do
          stack.validations.push(Map.new)

          _run_validations(errors, list)

          added = stack.validations.pop
          break if added.empty?
          list = [added]
        end

        if status.ok? and !errors.empty?
          status.source = errors
          status.update(412)
        end

        if status == 412 and status.source == errors and errors.empty?
          status.update(200)
        end

        errors
      ensure
        validated!(true)
      end

      alias_method 'run_validations!', 'run_validations'
      alias_method 'validate', 'run_validations'

      def _run_validations(errors, list)
        Array(list).each do |validations|
          validations.each do |keys, chain|
            chain.each do |callback|
              next unless callback and callback.respond_to?(:to_proc)

              number_of_errors = errors.size
              value = attributes.get(keys)

              returned =
                catch(:validation) do
                  args = Dao.args_for_arity([value, attributes], callback.arity)

                  prefixing(keys) do
                    object.instance_exec(*args, &callback)
                  end
                end

              errors_added = errors.size > number_of_errors

              case returned
                when Hash
                  map = Map.for(returned)
                  valid = map[:valid]
                  message = map[:message]
                when TrueClass, FalseClass
                  valid = returned
                  message = nil
                else
                  valid = !errors_added
                  message = nil
              end

              valid = false if errors_added

              message ||= callback.options[:message]
              message ||= (value.to_s.strip.empty? ? 'is blank' : 'is invalid')

              if not valid
                errors.add_from_source(keys, callback, message)
              else
                errors.delete_from_source(keys, callback)
              end
            end
          end
        end
      end

      def validated?
        @validated = false unless defined?(@validated)
        @validated
      end

      def validated!(boolean = true)
        @validated = !!boolean
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
          Map.options_for!(args)
          run_validations
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
