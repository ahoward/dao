module Dao
  module Middleware 
    class ParamsParser
      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env
        #if params = parse_formatted_parameters(env)
          #env["action_dispatch.request.request_parameters"] = params
        #end

        query_parameters = @env["action_controller.request.query_parameters"]
        request_parameters = @env["action_controller.request.request_parameters"]

        Rails.logger.info("query_parameters : #{ query_parameters.inspect }")
        Rails.logger.info("request_parameters : #{ request_parameters.inspect }")

        @app.call(@env)
      end
    end
  end
end
