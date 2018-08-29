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

#
  require_relative 'dao/_lib.rb'

#
  %w[
    action_controller
    active_support
    active_model
  ].each do |framework|
    begin
      require "#{ framework }/railtie"
    rescue LoadError
      begin
        require "#{ framework }"
      rescue LoadError
        raise
      end
    end
  end


#
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
    errors2html.rb
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
