module Dao
  class Conducer
    class Attributes < ::Map
      ### Attributes.dot_keys! if Attributes.respond_to?(:dot_keys!)

      class << Attributes
        def for(*args, &block)
          new(*args, &block)
        end
      end

      attr_accessor :conducer

      def initialize(*args, &block)
        conducers, args = args.partition{|arg| arg.is_a?(Conducer)}
        @conducer = conducers.shift
        super(*args, &block)
      end
    end
  end
end
