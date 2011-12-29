# -*- encoding : utf-8 -*-
# built-ins
#
  require 'enumerator'
  require 'set'

# dao libs
#
  module Dao
    Version = '4.2.2' unless defined?(Version)

    def version
      Dao::Version
    end

    def dependencies
      {
        'rails'         => [ 'rails'         , ' >= 3.0'   ] , 
        'map'           => [ 'map'           , ' >= 5.1'   ] , 
        'fattr'         => [ 'fattr'         , ' >= 2.2'   ] , 
        'tagz'          => [ 'tagz'          , ' >= 9.0'   ] , 
        'uuidtools'     => [ 'uuidtools'     , ' >= 2.1'   ] , 
        'multi_json'    => [ 'multi_json'    , ' >= 1.0.3' ] , 
        'upload_cache'  => [ 'upload_cache'  , ' >= 1.4.1' ] , 
        'wrap'          => [ 'wrap'          , ' >= 1.1.0' ] , 
        'rails_current' => [ 'rails_current' , ' >= 1.0'   ]
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call()
        ensure
          $LOAD_PATH.shift()
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      Dao.libdir{ libs.each{|lib| Kernel.load(lib) } }
    end

    extend(Dao)
  end

# gems
#
  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  if defined?(gem)
    Dao.dependencies.each do |lib, dependency|
      gem(*dependency)
      require(lib)
    end
  end

  %w[
    action_controller
    active_resource
    active_support
  ].each do |framework|
    begin
      require "#{ framework }/railtie"
    rescue LoadError
    end
  end


  Dao.load %w[
    blankslate.rb
    instance_exec.rb
    extractor.rb
    exceptions.rb
    support.rb
    slug.rb
    stdext.rb

    name.rb
    status.rb
    path_map.rb
    errors.rb
    form.rb
    validations.rb
    data.rb
    result.rb
    params.rb

    current.rb

    mode.rb
    route.rb
    path.rb
    endpoint.rb
    api.rb

    db.rb

    rails.rb
    active_record.rb
    mongo_mapper.rb

    conducer.rb
    image_cache.rb
  ]

# protect against rails' too clever reloading
#
=begin
  if defined?(Rails)
    unless defined?(unloadable)
      require 'active_support'
      require 'active_support/dependencies'
    end
    unloadable(Dao)
  end
  BEGIN{ Object.send(:remove_const, :Dao) if defined?(Dao) }
=end
