# -*- encoding : utf-8 -*-
# built-ins
#
  require 'enumerator'
  require 'set'
  require 'fileutils'
  require 'cgi'
  require 'tmpdir'
  require 'yaml'

# dao libs
#

  require "map"
  require "fattr"
  require "coerce"
  require "tagz"
  require "multi_json"
  require "uuidtools"
  require "wrap"
  require "rails_current"
  require "rails_current"
  require "rails_errors2html"


  module Dao
    Version = '6.0.0' unless defined?(Version)

    def version
      Dao::Version
    end

    def description
      "presenter, conducer, api, and better form objects for you rails' pleasure"
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
    messages.rb
    form.rb
    validations.rb
    data.rb
    result.rb
    params.rb

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
    upload.rb
  ]


  unless defined?(::UUIDTools::Config)
    ::UUIDTools.module_eval do
      Config = ::RbConfig # shuts up warnings...
    end
  end
