module Dao
  Version = '8.0.1' unless defined?(Version)

  def version
    Dao::Version
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

  def description
    "presenter, conductor, api, and better form objects for you rails' pleasure"
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
    Dao.libdir{ libs.each{|lib| Kernel.load(lib) } }
  end

  extend Dao
end
