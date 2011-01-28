module Dao
  class Api
    Initializers = {} unless defined?(Initializers)

    class << Api
      def new(*args, &block)
        allocate.instance_eval do
          before_initializers(*args, &block)
          initialize(*args, &block)
          after_initializers(*args, &block)
          self
        end
      end

      def initializers
        Initializers[self] ||= {:before => [], :after => []}
      end

      def before_initializers
        initializers[:before]
      end

      def before_initializer(&block)
        method_name = "before_initializer_#{ before_initializers.size }"
        define_method(method_name, &block)
        before_initializers.push(method_name)
      end

      def after_initializers
        initializers[:after]
      end

      def after_initializer(&block)
        after_initializers.push(block)
      end

      def superclasses
        @superclasses ||= ancestors.select{|ancestor| ancestor <= Dao::Api}
      end
    end

    def superclasses
      @superclasses ||= self.class.superclasses
    end

    def run_initializers(which, *args, &block)
      superclasses.each do |superclass|
        superclass.send("#{ which }_initializers").each do |method_name|
          send(method_name, *args, &block)
        end
      end
      send("#{ which }_initialize", *args, &block)
    end

    def before_initializers(*args, &block)
      run_initializers(:before, *args, &block)
    end

    def after_initializers(*args, &block)
      run_initializers(:after, *args, &block)
    end

    def before_initialize(*args, &block)
      :hook
    end

    def after_initialize(*args, &block)
      :hook
    end
  end
end
