# -*- encoding : utf-8 -*-
module DaoHelper
  def dao_form_for(*args, &block)
  # grok the model, or build one on the fly
  #
    model = args.flatten.select{|arg| arg.respond_to?(:persisted?)}.last

    options = args.extract_options!.to_options!

    args.push(options)

    if model.blank?
      name = 'form'
      model = Class.new(Dao::Conducer){ model_name(name) }.new(params[name])
      args.unshift(model)
    end

  # build urls to *relative to the current controller* (with respect to the
  # resource's state) unless specified...
  #
    html = dao_form_attrs(options.delete(:html) || {})

    if model
      url = options.delete(:url)
      method = options.delete(:method) || html.delete(:method)

      if model.persisted?
        method ||= :put
      else
        method ||= :post
      end

      url ||=
        case method
          when /post/
            url_for(:action => :create)
          when /put/
            url_for(:action => :update)
          else
            './'
        end

      options[:url] = url
      options[:html] = html.merge(:method => method)
    end

  # use a dao form builder...
  #
    options[:builder] = Dao::Form::Builder

  # delegate the rest of th magick to rails...
  #
    form_for(*args, &block)
  end
  alias_method(:dao_form, :dao_form_for)

  def dao_form_attrs(*args)
    args.flatten!

    options = args.extract_options!.to_options!.dup

    options[:class] =
      [args, options.delete(:class)].join(' ').scan(%r/[^\s]+/).push(' dao ').uniq.join(' ')

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

    unless options[:error!] == false
      @dao.error! unless(@dao.status =~ 200 or @dao.status == 420)
    end

    block ? block.call(@dao) : @dao
  end
end
ApplicationController.send(:include, DaoHelper)
