module DaoHelper
  def render_dao(result, *args, &block)
    if result.status =~ 200 or result.status == 420
      @result = result unless defined?(@result)
      render(*args, &block)
    else
      result.error!
    end
  end

  def dao(path, *args, &block)
    options = args.extract_options!.to_options!

    mode = options[:mode]

    if mode.blank?
      mode =
        case request.method
          when "GET"
            :read
          when "PUT", "POST", "DELETE"
            :write
          else
            :read
        end
    end

    @dao = api.send(mode, path, params)
    @dao.route = request.fullpath
    #@dao.mode = mode

    #unless options[:error!] == false
      @dao.error! unless @dao.status.ok?
    #end

    block ? block.call(@dao) : @dao
  end
end
ApplicationController.send(:include, DaoHelper)
