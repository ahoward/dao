# -*- encoding : utf-8 -*-
module DaoHelper
  def dao_form_for(*args, &block)
    model = args.flatten.select{|arg| arg.respond_to?(:persisted?)}.last

    options = args.extract_options!.to_options!

    options[:builder] = DaoFormBuilder

    if options[:post] or model.blank?
      options[:url] ||= (options.delete(:post) || request.fullpath)
      options[:method] ||= :post
    end

    args.push(options)

    if model.blank?
      name = 'form'
      model = Class.new(Dao::Conducer){ model_name(name) }.new(params[name])
      args.unshift(model)
    end

    form_for(*args, &block)
  end
  alias_method(:dao_form, :dao_form_for)

  class DaoFormBuilder
    def initialize(object_name, object, view, options, block)
    ##
    #
      @object_name = object_name
      @object = object
      @view = view
      @options = options
      @block = block

    ##
    #
      html = @options[:html] || {}
      html[:class] ||= 'dao'
      unless html[:class] =~ /(\s|\A)dao(\Z|\s)/o
        html[:class] << ' dao'
      end

    ##
    #
      @form = @object.form
    end

    def multipart?
      true
    end

    %w( [] []= get set has has? ).each do |method|
      class_eval <<-__
        def #{ method }(*args, &block)
          attributes.#{ method }(*args, &block)
        end
      __
    end

    def method_missing(method, *args, &block)
      return super unless @form.respond_to?(method)
      @form.send(method, *args, &block)
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
      @dao.error! unless(@dao.status =~ or @dao.status == 420)
    end

    block ? block.call(@dao) : @dao
  end
end
ApplicationController.send(:include, DaoHelper)
