module Dao
  def map_for(*args, &block)
    Map.for(*args, &block)
  end
  alias_method(:map, :map_for)
  alias_method(:hash, :map_for)

  def options_for!(args)
    Map.options_for!(args)
  end

  def options_for(args)
    Map.options_for(args)
  end

  def db(*args, &block)
    if args.empty? and block.nil?
      Db.instance
    else
      method = args.shift
      Db.instance.send(method, *args, &block)
    end
  end

  %w( to_dao as_dao ).each do |method|
    module_eval <<-__, __FILE__, __LINE__ - 1

      def #{ method }(object, *args, &block)
        case object
          when Array
            object.map{|element| Dao.#{ method }(element, *args, &block)}

          else
            if object.respond_to?(:#{ method })
              object.send(:#{ method }, *args, &block)
            else
              if object.respond_to?(:to_hash)
                object.to_hash
              else
                object
              end
            end
        end
      end

    __
  end

  def unindent!(s)
    margin = nil
    s.each_line do |line|
      next if line =~ %r/^\s*$/
      margin = line[%r/^\s*/] and break
    end
    s.gsub! %r/^#{ margin }/, "" if margin
    margin ? s : nil
  end

  def unindent(s)
    s = "#{ s }"
    unindent!(s)
    s
  end

  def name_for(path, *keys)
    Form.name_for(path, *keys)
  end

  def parse(*args, &block)
    Params.process(*args, &block)
  end

  def normalize_parameters(params)
    Params.normalize_parameters(params)
  end

  def current
    @current ||=
      Map.new(
        :controller => nil
      )
  end

  def current_controller(*args)
    current.controller = args.first unless args.empty?
    current.controller || mock_controller
  end
  alias_method('controller', 'current_controller')

  def current_controller=(controller)
    current.controller = controller
  end
  alias_method('controller=', 'current_controller=')

  %w( request response session ).each do |attr|
    module_eval <<-__, __FILE__, __LINE__
      def current_#{ attr }
        @current_#{ attr } ||= current_controller.instance_eval{ #{ attr } }
      end
      def current_#{ attr }=(value)
        @current_#{ attr } = value
      end
      def #{ attr }
        current_#{ attr }
      end
    __
  end

  def root
    if defined?(Rails.root) and Rails.root
      Rails.root
    else
      '.'
    end
  end

  def key_for(*keys)
    key = keys.flatten.join('.').strip
    key.split(%r/\s*[,.:_-]\s*/).map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
  end

  def mock_controller
    ensure_rails_application do
      require 'action_dispatch/testing/test_request.rb'
      require 'action_dispatch/testing/test_response.rb'
      store = ActiveSupport::Cache::MemoryStore.new
      controller = defined?(ApplicationController) ? ApplicationController.new : ActionController::Base.new
      controller.perform_caching = true
      controller.cache_store = store
      request = ActionDispatch::TestRequest.new
      response = ActionDispatch::TestResponse.new
      controller.request = request
      controller.response = response
      controller.send(:initialize_template_class, response)
      controller.send(:assign_shortcuts, request, response)
      controller.send(:default_url_options).merge!(DefaultUrlOptions) if defined?(DefaultUrlOptions)
      controller
    end
  end

  def ensure_rails_application(&block)
    if Rails.application.nil?
      mock = Class.new(Rails::Application)
      Rails.application = mock.instance
      begin
        block.call()
      ensure
        Rails.application = nil
      end
    else
      block.call()
    end
  end

  def normalize_parameters(params)
    dao = (params.delete('dao') || {}).merge(params.delete(:dao) || {})

    unless dao.blank?
      dao.each do |key, paths_and_values|
        params[key] = nil
        next if paths_and_values.blank?

        map = Map.new

        paths_and_values.each do |path, value|
          keys = keys_for(path)
          map.set(keys => value)
        end

        params[key] = map
      end
    end

    params[:dao] = :normalized
    params
  end

  def keys_for(keys)
    keys.strip.split(%r/\s*[,._-]\s*/).map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
  end
end
