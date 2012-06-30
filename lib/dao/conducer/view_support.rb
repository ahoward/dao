# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    ViewSupport = proc do
      include Tagz.globally

      class << Conducer
        include Tagz.globally

        def install_routes!
          url_helpers = Rails.application.try(:routes).try(:url_helpers)
          include(url_helpers) if url_helpers
          include(ActionView::Helpers) if defined?(ActionView::Helpers)
          extend(url_helpers) if url_helpers
          extend(ActionView::Helpers) if defined?(ActionView::Helpers)
        end
      end
    end
  end
end
