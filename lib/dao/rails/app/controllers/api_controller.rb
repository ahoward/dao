class APIController < ApplicationController
  layout false

  skip_before_filter true
  skip_before_filter :verify_authenticity_token

  before_filter :setup_api

  ### skip_before_filter :set_current_user if Rails.env.production?

##
# /api/foo/2/bar/4 -> api.call('/foo/2/bar/4')
#
  def call
    path = params[:path]
    mode = params['mode'] || (request.get? ? 'read' : 'write')

    result = api.mode(mode).call(path, params)

    respond_with(result)
  end

##
#
  def index
    json = json_for(api.index)

    respond_to do |wants|
      wants.json{ render(:json => json) }
      wants.html{ render(:text => json, :content_type => 'text/plain') }
    end
  end

protected

  def respond_with(result)
    json = json_for(result)

    respond_to do |wants|
      wants.json{ render :json => json, :status => result.status.code }
      wants.html{ render :text => json, :status => result.status.code, :content_type => 'text/plain' }
    end
  end

# if you don't have yajl-ruby and yajl/json_gem loaded your json will suck
#
  def json_for(object)
    if Rails.env.production?
      ::JSON.generate(object)
    else
      ::JSON.pretty_generate(object, :max_nesting => 0)
    end
  end

  def setup_api
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
