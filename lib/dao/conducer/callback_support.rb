# -*- encoding : utf-8 -*-
module Dao
  class Conducer
    CallbackSupport = proc do
      include Wrap

      class << self
        def method_missing(method, *args, &block)
          case method.to_s
            when %r/\A(before|after)_(.*)\Z/
              lifecycle, method = $1, $2
              send(lifecycle, method, *args, &block)
            else
              super
          end
        end
      end
    end
  end
end
