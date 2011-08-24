class APIController < ApplicationController
  layout false

  skip_before_filter :verify_authenticity_token

  before_filter :setup_api
  before_filter :setup_mode
  before_filter :setup_path

  WhiteList = Set.new( %w( ping index ) )
  BlackList = Set.new( %w( ) )

  def index
    result = call(path, params)
    respond_with(result)
  end

protected

  def call(path, params)
    @result = api.mode(@mode).call(path, params)
  end

  def respond_with(object, options = {})
    json = json_for(object)

    status = object.status rescue (options[:status] || 200)
    status = status.code if status.respond_to?(:code)

    respond_to do |wants|
      wants.json{ render :json => json, :status => status }
      wants.html{ render :text => json, :status => status, :content_type => 'text/plain' }
      wants.xml{ render :text => 'no soup for you!', :status => 403 }
    end
  end

  def json_for(object)
    begin
      if Rails.env.production?
        ::JSON.generate(object)
      else
        ::JSON.pretty_generate(object, :max_nesting => 0)
      end
    rescue Object => e
      Rails.logger.error(e)
      YAML.load( object.to_yaml ).to_json
    end
  end

  def setup_path
    @path = params[:path] || params[:action] || 'index'
    unless api.route?(@path) or @path=='index'
      render :nothing => true, :status => 404
    end
  end

  def setup_mode
    @mode = params['mode'] || (request.get? ? 'read' : 'write')
  end

  def path
    @path
  end

  def mode
    @mode
  end

##
# you'll likely want to customize this for you app as it makes a few
# assumptions about how to find and authenticate users
#
  def setup_api
    if white_listed?(path)
      @api = Api.new
      return
    end

    email, password = http_basic_auth_info

    if !email.blank? and !password.blank?
      user = User.find_by_email(email)
      if user.password == password
        @api = Api.new(user)
      else
        render(:nothing => true, :status => :unauthorized)
        return
      end
    else
      if defined?(current_user)
        if current_user
          @api = Api.new(current_user)
        else
          render(:nothing => true, :status => :unauthorized)
        end
      else
        @api = Api.new
      end
    end
  end

  def api
    @api
  end

  def self.white_listed?(path)
    WhiteList.include?(path.to_s)
  end

  def white_listed?(path)
    self.class.white_listed?(path)
  end

  def self.black_listed?(path)
    BlackList.include?(path.to_s)
  end

  def black_listed?(path)
    self.class.black_listed?(path)
  end

  def http_basic_auth
    @http_basic_auth ||= (
      request.env['HTTP_AUTHORIZATION']   ||
      request.env['X-HTTP_AUTHORIZATION'] ||
      request.env['X_HTTP_AUTHORIZATION'] ||
      request.env['REDIRECT_X_HTTP_AUTHORIZATION'] ||
      ''
    )
  end

  def http_basic_auth_info
    username, password =
      ActiveSupport::Base64.decode64(http_basic_auth.split.last.to_s).split(/:/, 2)
  end
end

ApiController = APIController ### rails is a bitch - shut her up
