module Dao
  Version = '8.0.1' unless defined?(Version)

  class << self
    def version
      Version
    end

    def summary
      "presenter, conductor, api, and better form objects for your rails' pleasure"
    end

    def dependencies
      {
        'rails'             => [ 'rails'             , ' ~> 6.0'  ] ,
        'map'               => [ 'map'               , ' ~> 6.6'  ] ,
        'fattr'             => [ 'fattr'             , ' ~> 2.4'  ] ,
        'tagz'              => [ 'tagz'              , ' ~> 9.10' ] ,
        'rails_current'     => [ 'rails_current'     , ' ~> 2.2'  ] ,
      }
    end

    def load_dependencies!
      begin 
        require 'rubygems'
      rescue LoadError
        nil
      end

      dependencies.each do |lib, dependency|
        gem(*dependency) if defined?(gem)
        require(lib)
      end
    end

    def libdir(*args, &block)
      @libdir ||= File.dirname(File.expand_path(__FILE__).sub(/\.rb$/,''))
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
      libdir{ libs.each{|lib| Kernel.load(lib) } }
    end
  end
end
