

Testing Dao do
## api
#
  testing 'that an api class for your application can be built using a simple dsl' do
    assert{
      api_class =
        Dao.api do
          ### dsl
        end
    }
  end

  testing 'that apis can have callable endpoints added to them which accept params and return results' do
    captured = []

    api_class =
      assert{
        Dao.api do
          endpoint(:foo) do |params, result|
            captured.push(params, result)
          end
        end
      }
    api = assert{ api_class.new }
    result = assert{ api.call(:foo, {}) }
    assert{ result.is_a?(Hash) }
  end

  testing 'that endpoints are automatically called according to arity' do
    api = assert{ Class.new(Dao.api) }
    assert{ api.class_eval{ endpoint(:zero){|| result.update :args => [] } } }
    assert{ api.class_eval{ endpoint(:one){|a| result.update :args => [a]} } }
    assert{ api.class_eval{ endpoint(:two){|a,b| result.update :args => [a,b]} } }

    assert{ api.new.call(:zero).args.size == 0 }
    assert{ api.new.call(:one).args.size == 1 }
    assert{ api.new.call(:two).args.size == 2 }
  end

  testing 'that endpoints have an auto-vivifying params/result' do
    api = assert{ Class.new(Dao.api) }
    assert{ api.class_eval{ endpoint(:foo){ params; result; } } }
    result = assert{ api.new.call(:foo) }
    assert{ result.path.to_s =~ /foo/ }
  end

  testing 'that an api can be called with different modes' do
    api_class =
      assert{
        Dao.api do
          call(:foo) do
            data.modes = []

            Dao::Mode.list.each do |mode|
              send(mode){ data.modes.push(mode) }
            end
          end
        end
      }
    api = assert{ api_class.new }

    Dao::Mode.list.each do |mode|
      result = api.mode(mode).call(:foo)
      assert{ result.data.modes.include?(mode) }
    end
  end

  testing 'that options/head/get are considered read modes' do
    read_mode = assert{ Dao::Mode.read }

    api_class =
      assert{
        Dao.api do
          call(:foo) do
            data.update :modes => []
            read { data.modes.push(read_mode) }
          end
        end
      }
    api = assert{ api_class.new }

    Dao::Mode::Read.each do |mode|
      result = assert{ api.mode(mode).call(:foo) }
      assert{ result.data.modes == [read_mode] }
    end
  end

  testing 'that post/put/delete/trace/connect are considered write modes' do
    write_mode = assert{ Dao::Mode.write }

    api_class =
      assert{
        Dao.api do
          call(:foo) do
            data.update :modes => []
            write { data.modes.push(write_mode) }
          end
        end
      }
    api = assert{ api_class.new }

    Dao::Mode::Write.each do |mode|
      result = assert{ api.mode(mode).call(:foo) }
      assert{ result.data.modes == [write_mode] }
    end
  end

  testing 'that the first, most specific, mode block encountered fires first' do
    api_class =
      assert{
        Dao.api do
          call(:foo) do
            data.update :modes => []
            Dao::Mode::Read.each do |mode|
              send(mode){ data.modes.push(mode) }
            end
            read { data.modes.push(Dao::Mode.read) }
          end
        end
      }
    api = assert{ api_class.new }

    read = Dao::Mode.read
    result = assert{ api.mode(read).call(:foo) }
    assert{ result.data.modes == [read] }

    Dao::Mode::Read.each do |mode|
      result = assert{ api.mode(mode).call(:foo) }
      assert{ result.data.modes == [mode] }
    end
  end

## results
#
  testing 'that results can be created' do
    result = assert{ Dao::Result.new }
    assert{ result.path }
    assert{ result.status }
    assert{ result.errors }
    assert{ result.params }
    assert{ result.data }
  end

  testing 'that results can be created with a path' do
    result = assert{ Dao::Result.new('/api/foo/bar') }
    assert{ result.path == '/api/foo/bar' }
  end

## paths
#
  testing 'that simple paths can be contstructed/compiled' do
    path = assert{ Dao::Path.for('./api/../foo/bar')  }
    assert{ path =~ %r|^/| }
    assert{ path !~ %r|[.]| }
    assert{ path.params.is_a?(Hash) }
    assert{ path.keys.is_a?(Array) }
    assert{ path.pattern.is_a?(Regexp) }
  end

## routes
#
  testing 'that an api has a list of routes' do
    api_class =
      assert{
        Dao.api do
        end
      }
    assert{ api_class.routes.is_a?(Array) }
  end

  testing 'that routed endpoints call be declared' do
    api_class =
      assert{
        Dao.api do
          call('/users/:user_id/comments/:comment_id') do
            data.update(params)
          end
        end
      }
    api = api_class.new
  end

  testing 'that routed methods can be called with embedded params' do
    api_class =
      assert{
        Dao.api do
          call('/users/:user_id/comments/:comment_id') do 
            data.update(params)
          end
        end
      }
    api = api_class.new

    {
      '/users/4/comments/2' => {},
      '/users/:user_id/comments/:comment_id' => {:user_id => 4, :comment_id => 2},
    }.each do |path, params|
      result = assert{ api.call(path, params) }
      assert{ result.data.user_id.to_s =~ /4/ }
      assert{ result.data.comment_id.to_s =~ /2/ }
      assert{ result.path == '/users/4/comments/2' }
      assert{ result.route == '/users/:user_id/comments/:comment_id' }
    end
  end

## doc
#
  testing 'that apis can be documented via the api' do
    api_class =
      assert {
        Dao.api {
          description 'foobar'
          doc 'signature' => {'read' => '...', 'write' => '...'} 
          endpoint('/barfoo'){}
        }
      }
    api_class_index = assert{ api_class.index.is_a?(Hash) }
    api = assert{ api_class.new }
    api_index = assert{ api.index.is_a?(Hash) }
    assert{ api_class_index==api_index }
  end

# aliases
#
  testing 'that apis can alias methods' do
    api_class =
      assert {
        Dao.api {
          call('/barfoo'){ data.update(:k => :v) }
          call('/foobar', :alias => '/barfoo')
        }
      }
    api = assert{ api_class.new }
    assert{ api.call('/barfoo').data.k == :v }
    assert{ api.call('/foobar').data.k == :v }
  end

protected
  def hash_equal(a, b)
    array = lambda{|h| h.to_a.map{|k,v| [k.to_s, v]}.sort}
    array[a] == array[b]
  end

  def api(&block)
    api_class = assert{ Dao.api(&block) }
    api = assert{ api_class.new }
  end
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')

  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
  require File.join(testdir, 'helper')
}
