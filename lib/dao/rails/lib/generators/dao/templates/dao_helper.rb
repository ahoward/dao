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

  def dao_form_for(*args, &block)
    options = args.extract_options!.to_options!

    model = args.flatten.select{|arg| arg.respond_to?(:new_record?)}.last

    if model
      first = args.first
      url = options.delete(:url)
      method = options.delete(:method)
      html = dao_form_attrs(options)

      options.clear

      if model.new_record?
        url ||= url_for(first)
        method ||= :post
      else
        url ||= url_for(first)
        method ||= :put
      end

      options[:url] = url
      options[:html] = html.dup.merge(:method => method)

      args.push(options)
      
      form_for(*args) do
        block.call(model.form)
      end
    else
      args.push(request.fullpath) if args.empty?
      args.push(dao_form_attrs(options))
      form_tag(*args, &block)
    end
  end

  def dao_form_attrs(*args)
    args.flatten!
    options = args.extract_options!.to_options!.dup
    options[:class] ||= []
    options[:class] = Array(options[:class])
    options[:class].push('dao')
    options[:class].push(args.map{|arg| arg.to_s})
    options[:class].flatten!
    options[:class].compact!
    options[:class].uniq!
    options[:class] = options[:class].join(' ')
    options[:enctype] ||= "multipart/form-data"
    options
  end

end
ApplicationController.send(:include, DaoHelper)
