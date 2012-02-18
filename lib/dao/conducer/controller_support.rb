# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    ControllerSupport = proc do
    ##
    #
      def controller
        @controller ||= (Dao.current_controller || Dao.mock_controller)
        @controller
      end

      def controller=(controller)
        @controller = controller
      ensure
        default_url_options[:protocol] = @controller.request.protocol
        default_url_options[:host] = @controller.request.host
        default_url_options[:port] = @controller.request.port

        self.action = @controller.send(:action_name).to_s
      end

      def set_controller(controller)
        self.controller = controller
      end

    ##
    #
      class Action < ::String
        fattr :object

        def initialize(action, object = nil)
          super(action)
          @object = object
        end

        def action
          to_s
        end

        Synonyms = {
          'new' => 'create',
          'edit' => 'update'
        }

        def call(method, *args, &block)
          return unless object

          action_method = "#{ method }_for_#{ action }"

          synonym = Synonyms[action] || Synonyms.invert[action]
          synonym_method = "#{ method }_for_#{ synonym }" if synonym

          [action_method, synonym_method].compact.each do |method|
            if object.respond_to?(method)
              result = Dao.call(object, method, *args, &block)
              return result
            end
          end

          nil
        end
      end

      def action
        @action ||= Action.new('new', self)
      end

      def action=(action)
        @action = Action.new(action, self)
      end

    ##
    #
      controller_delegates = %w(
        render
        render_to_string
      )

      controller_delegates.each do |method|
        module_eval <<-__, __FILE__, __LINE__
          def #{ method }(*args, &block)
            controller.#{ method }(*args, &block)
          end
        __
      end
    end
  end
end
