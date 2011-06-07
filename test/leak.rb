##
#
  require 'rubygems'
  #gem 'activesupport', '>= 3.0.7'
  #require 'active_support'
  #require 'active_support/dependencies'

  require 'rails/all'
  require 'dao'

##
#
  gc =
    lambda do
      10.times{ GC.start }
    end

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
      result.route || abort(result.inspect)

      ActiveSupport::Dependencies.unloadable(Api)
      ActiveSupport::Dependencies.remove_unloadable_constants!
      gc.call()
    end

##
#
  n = 10

paths = 0
ObjectSpace.each_object(Dao::Path){ paths += 1}
p 'paths' => paths

  leak.call()
  before = Process.size

paths = 0
ObjectSpace.each_object(Dao::Path){ paths += 1}
p 'paths' => paths

  leak.call()
  after = Process.size

paths = 0
ObjectSpace.each_object(Dao::Path){ paths += 1}
p 'paths' => paths

  delta = [after.first - before.first, after.last - before.last]

  p :before => before 
  p :after => after 
  p :delta => delta


##
#
  BEGIN {

    module Process
      def self.size pid = Process.pid 
        stdout = `ps wwwux -p #{ pid }`.split(%r/\n/)
        vsize, rsize = stdout.last.split(%r/\s+/)[4,2].map{|i| i.to_i}
      end

      def self.vsize
        size.first.to_i
      end

      def self.rsize
        size.last.to_i
      end
    end

  }
