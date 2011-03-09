module DaoHelper
  def render_dao(result, *args, &block)
    if result.status =~ 200 or result.status == 420
      @result = result unless defined?(@result)
      render(*args, &block)
    else
      result.error!
    end
  end
end
ApplicationController.send(:include, DaoHelper)
