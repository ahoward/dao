module Dao
  class Mode < ::String
    class << Mode
      def for(mode)
        mode.is_a?(Mode) ? mode : Mode.new(mode.to_s)
      end

      def list
        List
      end

      def default
        Mode.for(:read)
      end
    end

    Verbs = %w( options get head post put delete trace connect )

    Verbs.each do |verb|
      const = verb.downcase.capitalize
      unless const_defined?(const)
        mode = Mode.for(verb.downcase)
        const_set(const, mode)
      end
    end

    Read = Get unless defined?(Read)
    Write = Post unless defined?(Write)

    List = Verbs + %w( read write )

    List.each do |method|
      const = method.downcase.capitalize
      define_method(method){ const_get(const) }
    end

    def ==(other)
      super(Mode.for(other))
    end
  end
end
