module Dao
  class Api
    class DSL < BlankSlate
      attr_accessor :api

      def initialize(api)
        @api = api
        #@evaluate = Object.instance_method(:instance_eval).bind(self)
      end

      def evaluate(&block)
        #@evaluate.call(&block)
        @api.module_eval(&block)
      ensure
        #no_docs_left_on_stack!
      end

      def no_docs_left_on_stack!
        raise "no endpoint for #{ docs.inspect }" unless docs.empty?
      end

      %w( endpoint doc docs description desc ).each do |method|
        module_eval <<-__, __FILE__, __LINE__ - 1

          def #{ method }(*args, &block)
            api.#{ method }(*args, &block)
          end

        __
      end
    end

    class << Api
      def evaluate(&block)
        @dsl ||= DSL.new(api=self)
        @dsl.evaluate(&block)
      end
    end
  end

  def Dao.api(&block)
    if block
      api = Class.new(Api)
      api.evaluate(&block)
      api
    else
      Api
    end
  end
end
