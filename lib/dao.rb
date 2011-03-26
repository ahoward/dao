# built-ins
#
  require 'enumerator'
  require 'set'
  #require 'fileutils'
  #require 'pathname'
  #require 'yaml'
  #require 'yaml/store'

# dao libs
#
  module Dao
    Version = '2.2.2' unless defined?(Version)

    def version
      Dao::Version
    end

    def dependencies
      {
        'map' => ['map', '~> 2.7.0'],
        'tagz' => ['tagz', '~> 8.2.0'],
        'yajl' => ['yajl-ruby', '~> 0.8.1']
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

  require 'yajl/json_gem'

  Dao.load %w[
    blankslate.rb
    instance_exec.rb
    exceptions.rb
    support.rb
    slug.rb
    stdext.rb

    result.rb
    params.rb
    status.rb
    data.rb
    form.rb
    errors.rb
    validations.rb
    presenter.rb

    mode.rb
    path.rb
    interface.rb
    api.rb


    rails.rb
    active_record.rb
    mongo_mapper.rb
  ]

  Dao.autoload(:Db, Dao.libdir('db.rb'))

  unless defined?(D)
    D = Dao
  end

  if defined?(Rails.env)
    unless Rails.env.production?
      unloadable(Dao)
      unloadable(D)
    end
  end
