module DaoHelper
  def render_dao(result, *args, &block)
    if result.status =~ 200 or result.status == 420
      render(*args, &block)
    else
      render(:text => result.status, :status => result.status.code)
    end
  end
end
ApplicationController.send(:include, DaoHelper)
