Api = 
  Dao.api do

    description 'ping!'
    interface('/ping'){
      data.update :time => Time.now
    }




  ## this is simply a suggest way to model your api.  it is not required.
  #
    attr_accessor :effective_user
    attr_accessor :real_user

    def initialize(*args)
      options = args.extract_options!.to_options!
      effective_user = args.shift || options[:effective_user] || options[:user]
      real_user = args.shift || options[:real_user] || effective_user
      @effective_user = user_for(effective_user) if effective_user
      @real_user = user_for(real_user) if real_user
      @real_user ||= @effective_user
    end

    def user_for(arg)
      User.find(arg)
    end

    alias_method('user', 'effective_user')
    alias_method('user=', 'effective_user=')

    def api
      self
    end

    def logged_in?
      @effective_user and @real_user
    end

    def user?
      logged_in?
    end

    def current_user
      effective_user
    end

    def current_user?
      !!effective_user
    end
  end


unloadable(Api)
