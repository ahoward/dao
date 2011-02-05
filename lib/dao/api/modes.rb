
module Dao
  class Api
    class << Api
      def modes(*modes)
        @modes ||= []
        modes.flatten.compact.map{|mode| Api.add_mode(mode)} unless modes.empty?
        @modes
      end

      def modes=(*modes)
        modes(*modes)
      end

      def add_mode(mode)
        modes.push(mode = Mode.for(mode)).uniq!

        module_eval(<<-__, __FILE__, __LINE__ - 1)

          def #{ mode }(*args, &block)
            if args.empty?
              if catching_results?
                if self.mode == #{ mode.inspect }
                  mode(#{ mode.inspect }, &block)
                  return!
                end
              else
                mode(#{ mode.inspect }, &block)
              end
            else
              mode(#{ mode.inspect }) do
                call(*args, &block)
              end
            end
          end

          def #{ mode }?(&block)
            mode?(#{ mode.inspect }, &block)
          end

        __

        mode
      end
    end

    def mode=(mode)
      @mode = Mode.for(mode)
    end

    def mode(*args, &block)
      @mode ||= Mode.default

      if args.empty? and block.nil?
        @mode
      else
        if block
          mode = self.mode
          self.mode = args.shift
          begin
            return(instance_eval(&block))
          ensure
            self.mode = mode
          end
        else
          self.mode = args.shift
          return(self)
        end
      end
    end

    def mode?(mode, &block)
      condition = self.mode == mode

      if block.nil?
        condition
      else
        send(mode, &block) if condition
      end
    end
  end

  Api.modes = Mode.list

  Api.before_initializer do |*args|
    @mode = Mode.default
  end
end
