module Dao
  module Wrap
    def Wrap.included(other)
      super
    ensure
      other.send(:instance_eval, &ClassMethods)
      other.send(:class_eval, &InstanceMethods)
    end

    def Wrap.code_for(method)
      name = method.name.to_s
      arity = method.arity

      case
        when arity == 0
          signature = <<-__.strip
            def #{ name }(&block)
              args = []
          __

        when arity < 0
          argv = Array.new(arity.abs - 1){|i| "arg#{ i }"}
          argv.push('*args')
          argv = argv.join(', ')

          signature = <<-__.strip
            def #{ name }(#{ argv }, &block)
              args = [#{ argv }]
          __

        when arity > 0
          argv = Array.new(arity){|i| "arg#{ i }"}
          argv = argv.join(', ')

          signature = <<-__.strip
            def #{ name }(#{ argv }, &block)
              args = [#{ argv }]
          __
      end

      code =
        <<-__
          #{ signature.strip }
           
            if running_callbacks?(#{ name.inspect })
              return wrapped_#{ name }(*args, &block)
            end

            running_callbacks(#{ name.inspect }) do
              catch(:halt) do
                return false if run_callbacks(:before, #{ name.inspect }, args)==false

                begin
                  result = wrapped_#{ name }(*args, &block)
                ensure
                  run_callbacks(:after, #{ name.inspect }, [result]) unless $!
                end
              end
            end
          end
        __

      return code
    end

    ClassMethods = proc do
      def method_added(name)
        return super if wrapping?
        begin
          super
        ensure
          wrap!(name) if wrapped?(name)
        end
      end

      def include(other)
        super
      ensure
        other.instance_methods.each do |name|
          if wrapped?(name)
            begin
              remove_method(name)
            rescue NameError
              nil
            end
            wrap!(name)
          end
        end
      end

      def wrap(name, *args, &block)
        wrapped!(name)

        wrap!(name) if
          begin
            instance_method(name)
            true
          rescue NameError
            false
          end
      end

      def wrapped!(name)
        name = name.to_s
        wrapped.push(name) unless wrapped.include?(name)
        name
      end

      def wrapped
        @wrapped ||= []
      end

      def wrapped?(name)
        ancestors.any?{|ancestor| ancestor.respond_to?(:wrapped) and ancestor.wrapped.include?(name.to_s)}
      end

      def wrap!(name)
        name = name.to_s
        method = instance_method(name)

        wrapping! name do
          name = name.to_s
          wrapped_name = "wrapped_#{ name }"

          begin
            remove_method(wrapped_name)
          rescue NameError
            nil
          end

          alias_method(wrapped_name, name)

          module_eval(Wrap.code_for(method))
        end
      end

      def wrapping!(name, &block)
        name = name.to_s
        @wrapping ||= []

        return if @wrapping.last == name

        @wrapping.push(name)

        begin
          block.call
        ensure
          @wrapping.pop
        end
      end

      def wrapping?(*name)
        @wrapping ||= []

        if name.empty?
          !@wrapping.empty?
        else
          @wrapping.last == name.last.to_s
        end
      end

      def callbacks
        @callbacks ||= Map.new
      end

      def initialize_callbacks!(name)
        callbacks[name] ||= Map[ :before, [], :after, [] ]
        callbacks[name]
      end

      def before(name, *args, &block)
        wrap(name) unless wrapped?(name)
        name = wrap_expand_aliases(name)
        cb = initialize_callbacks!(name)
        cb.before.push(args.shift || block)
      end

      def after(name, *args, &block)
        wrap(name) unless wrapped?(name)
        name = wrap_expand_aliases(name)
        cb = initialize_callbacks!(name)
        cb.after.push(args.shift || block)
      end

      def wrap_aliases
        @@wrap_aliases ||= Hash.new
      end

      def wrap_alias(dst, src)
        wrap_aliases[dst.to_s] = src.to_s
      end

      def wrap_expand_aliases(name)
        name = name.to_s
        loop do
          break unless wrap_aliases.has_key?(name)
          name = wrap_aliases[name]
        end
        name
      end
    end

    InstanceMethods = proc do
      def running_callbacks(name, &block)
        name = name.to_s
        @running_callbacks ||= []
        return block.call() if @running_callbacks.last == name

        @running_callbacks.push(name)

        begin
          block.call()
        ensure
          @running_callbacks.pop
        end
      end

      def running_callbacks?(*name)
        @running_callbacks ||= []

        if name.empty?
          @running_callbacks.last
        else
          @running_callbacks.last == name.last.to_s
        end
      end

      def run_callbacks(which, name, argv)
        which = which.to_s.to_sym
        name = name.to_s
        list = []

        self.class.ancestors.each do |ancestor|
          next unless ancestor.respond_to?(:callbacks)

          if ancestor.callbacks.is_a?(Map) and ancestor.callbacks[name].is_a?(Map)
            callbacks = ancestor.callbacks[name][which]
            accumulate = (which == :before ? :unshift : :push)
            list.send(accumulate, *callbacks) if callbacks.is_a?(Array)
          end
        end

        list.each do |callback|
          block = callback.respond_to?(:call) ? callback : proc{ send(callback.to_s.to_sym) }
          args = argv.slice(0 .. (block.arity > 0 ? block.arity : -1))
          result = instance_exec(*args, &block)
          return false if result == false
        end

        true
      end

      def halt!(*args)
        value = args.size == 0 ? false : args.shift
        throw(:halt, value)
      end
    end
  end
end
