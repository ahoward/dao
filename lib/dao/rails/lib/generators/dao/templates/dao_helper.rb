module DaoHelper
  def render_dao(result, *args, &block)
    if result.status =~ 200 or result.status == 420
      @result = result unless defined?(@result)
      render(*args, &block)
    else
      result.error!
    end
  end

  def dao(path, params, mode = nil)
    unless mode
      case request.method
      when "GET"
        mode = :read
      when "PUT", "POST", "DELETE"
        mode = :write
      else
        # do nothing - the user must specificy the mode explicity
      end
    end
    result = api.send(mode, path, params)
    result.route = request.fullpath
    result
  end
end
ApplicationController.send(:include, DaoHelper)
