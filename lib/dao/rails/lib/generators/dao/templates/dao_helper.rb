# -*- encoding : utf-8 -*-
module DaoHelper
  def dao_form_for(*args, &block)
    options = args.extract_options!.to_options!

    model = args.flatten.detect{|arg| arg.respond_to?(:persisted?)}

    if model
      first = args.shift
      url = args.shift || options.delete(:url)

      method = options.delete(:method)
      html = dao_form_attrs(options)

      options.clear

      if model.persisted?
        method ||= :put
      else
        method ||= :post
      end

      url =
        case method
          when :put
            url_for(:action => :update)
          when :post
            url_for(:action => :create)
          else
            './'
        end

      options[:url] = url
      options[:html] = html.dup.merge(:method => method)
      #options[:builder] = Dao::Form::Builder

      args.push(model)
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

  alias_method(:dao_form, :dao_form_for)

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
