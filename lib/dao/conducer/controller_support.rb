# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    ControllerSupport = proc do
    ##
    #
      def controller
        unless defined?(@controller)
          set_controller(Conducer.controller)
        end
        @controller
      end

      def controller=(controller)
        set_controller(controller)
      end

      def set_controller(controller)
        @controller = controller
      ensure
        if defined?(default_url_options)
          [:protocol, :host, :port].each{|attr| default_url_options[attr] = @controller.request.send(attr)}
        end
        @action = Action.new((@controller.send(:action_name) || :index).to_s, self)
      end

      def request
        @controller.send(:request) if @controller
      end

    ##
    #
      class Action < ::String
        fattr :conducer

        def initialize(action, conducer = nil)
          super(action.to_s.downcase.strip)
          @conducer = conducer
        end

        def action
          to_s
        end

        def ==(other)
          super(other.to_s)
        end

        Synonyms = {
          'new'    => 'create',
          'create' => 'new',

          'edit'   => 'update',
          'update' => 'edit'
        }

        def call(method, *args, &block)
          return unless conducer

          action_method = "#{ method }_for_#{ action }"

          return Dao.call(conducer, action_method, *args, &block) if conducer.respond_to?(action_method)

          if((synonym = Synonyms[action]))
            action_method = "#{ method }_for_#{ synonym }"
            return Dao.call(conducer, action_method, *args, &block) if conducer.respond_to?(action_method)
          end

          nil
        end
      end

      def action
        unless defined?(@action)
          set_action(:new)
        end
        @action
      end

      def set_action(action)
        unless action.is_a?(Action)
          action = Action.new(action)
        end
        action.conducer = self
        @action = action
      end

      def action=(action)
        set_action(action)
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
