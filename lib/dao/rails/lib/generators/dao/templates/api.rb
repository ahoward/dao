# -*- encoding : utf-8 -*-
Api = 
  Dao.api do
  ##
  #
    README <<-__
      this a dao api
      
        so nice

      so good
    __

  ##
  #
    desc '/ping - hello world without a user'
    call('/ping'){
      data.update :time => Time.now
    }

    desc '/pong - hello world with a user'
    call('/pong'){
      require_current_user!
      data.update :time => Time.now
      data.update :current_user => current_user.id
    }

  ## this is simply a suggested way to model your api.  it is not required.
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

  ## no doubt you'll want to customize this!
  #
    def user_for(arg)
      User.respond_to?(:for) ? User.for(arg) : User.find(arg)
    end

    alias_method('user', 'effective_user')
    alias_method('user=', 'effective_user=')
    alias_method('current_user', 'effective_user')
    alias_method('current_user=', 'effective_user=')
    alias_method('effective_user?', 'effective_user')
    alias_method('real_user?', 'real_user')

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

    def require_effective_user!
      unless effective_user?
        status :unauthorized
        return!
      end
    end

    def require_real_user!
      unless real_user?
        status :unauthorized
        return!
      end
    end

    def require_current_user!
      require_effective_user! and require_real_user!
    end
    alias_method('require_user!', 'require_current_user!')
  end

## look for any other apis to load
#
  %w( api apis ).each do |dir|
    glob = File.expand_path(File.join(Rails.root, "app/#{ dir }/**/*.rb"))
    files = Dir.glob(glob).sort
    files.each{|file| ::Kernel.load(file)}
  end

## mo betta in development
#
  unloadable(Api)

## top level method shortcut
#
  module Kernel
  protected
    def api(*args, &block)
      Api.new(*args, &block)
    end
  end
