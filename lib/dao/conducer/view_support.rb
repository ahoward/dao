# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    ViewSupport = proc do
      url_helpers = Rails.application.try(:routes).try(:url_helpers)
      include(url_helpers) if url_helpers
      include(ActionView::Helpers) if defined?(ActionView::Helpers)

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
      end

      def set_controller(controller)
        self.controller = controller
      end

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
