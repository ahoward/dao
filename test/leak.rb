##
#
  require 'dao'
  require 'rubygems'
  gem 'activesupport', '>= 3.0.7'
  require 'active_support'
  require 'active_support/dependencies'

##
#
  leak =
    lambda do
      Api =
        Dao.api do
          1000.times do |i|
            call("/foobar-#{ i }") do
            end
          end
        end

      api = Api.new

      result = api.call('/foobar-1')
      p result.route

      ActiveSupport::Dependencies.unloadable(Api)
      ActiveSupport::Dependencies.remove_unloadable_constants!
    end

##
#
  n = 10

  leak.call()

  GC.start
  leak.call()
  GC.start

  p :before => Process.size


  GC.start
  leak.call()
  GC.start

  p :after => Process.size













##
#
  BEGIN {

    module Process
      def self.size pid = Process.pid 
        stdout = `ps wwwux -p #{ pid }`.split(%r/\n/)
        vsize, rsize = stdout.last.split(%r/\s+/)[4,2]
      end

      def self.vsize
        size.first
      end

      def self.rsize
        size.last
      end
    end

  }
