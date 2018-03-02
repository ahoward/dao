# -*- encoding : utf-8 -*-
require 'test_helper'

class DaoTest < ::Dao::TestCase
## api
#
  test 'that an api class for your application can be built using a simple dsl' do
    assert{
      Dao.api do
        ### dsl
      end
    }
  end

  test 'that apis can have callable endpoints added to them which accept params and return results' do
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

  test 'that endpoints are automatically called according to arity' do
    api = assert{ Class.new(Dao.api) }
    assert{ api.class_eval{ endpoint(:zero){|| result.update :args => [] } } }
    assert{ api.class_eval{ endpoint(:one){|a| result.update :args => [a]} } }
    assert{ api.class_eval{ endpoint(:two){|a,b| result.update :args => [a,b]} } }

    assert{ api.new.call(:zero).args.size == 0 }
    assert{ api.new.call(:one).args.size == 1 }
    assert{ api.new.call(:two).args.size == 2 }
  end

  test 'that endpoints have an auto-vivifying params/result' do
    api = assert{ Class.new(Dao.api) }
    assert{ api.class_eval{ endpoint(:foo){ params; result; } } }
    result = assert{ api.new.call(:foo) }
    assert{ result.path.to_s =~ /foo/ }
  end

  test 'that an api can be called with different modes' do
    Dao::Mode.list.each do |mode|
      api_class =
        assert{
          Dao.api do
            call(:foo) do
              send(mode){ data.update(:mode => mode) }
            end
          end
        }
      api = assert{ api_class.new }

      assert{ api.mode(mode).call(:foo).data[:mode] == mode }
    end
  end

  test 'that read==get' do
    api_class =
      assert{
        Dao.api do
          call(:foo) do
            read { data.update :answer => 42 }
          end

          call(:bar) do
            get { data.update :answer => 42.0 }
          end
        end
      }
    api = assert{ api_class.new }

    assert{ api.read.call(:foo).data.answer == 42 }
    assert{ api.get.call(:foo).data.answer == 42 }

    assert{ api.read.call(:bar).data.answer == 42.0 }
    assert{ api.get.call(:bar).data.answer == 42.0 }
  end

  test 'that write==post' do
    api_class =
      assert{
        Dao.api do
          call(:foo) do
            write { data.update :answer => 42 }
          end

          call(:bar) do
            post { data.update :answer => 42.0 }
          end
        end
      }
    api = assert{ api_class.new }

    assert{ api.write.call(:foo).data.answer == 42 }
    assert{ api.post.call(:foo).data.answer == 42 }

    assert{ api.write.call(:bar).data.answer == 42.0 }
    assert{ api.post.call(:bar).data.answer == 42.0 }
  end

  test 'that aliases are re-defined in scope' do
    api_class =
      assert{
        Dao.api do
          call(:foo) do
            data.update :a => mode
            read { data.update :b => mode }
            write { data.update :b => mode }
          end

          call(:bar) do
            data.update :a => mode
            get { data.update :b => mode }
            post { data.update :b => mode }
          end
        end
      }
    api = assert{ api_class.new }


    [:foo, :bar].each do |call|
      result = assert{ api.read.call(call) }
      assert{ result.data[:a] = Dao::Mode.read }
      assert{ result.data[:b] = Dao::Mode.read }

      result = assert{ api.get.call(call) }
      assert{ result.data[:a] = Dao::Mode.read }
      assert{ result.data[:b] = Dao::Mode.get }


      result = assert{ api.write.call(call) }
      assert{ result.data[:a] = Dao::Mode.write }
      assert{ result.data[:b] = Dao::Mode.write }

      result = assert{ api.post.call(call) }
      assert{ result.data[:a] = Dao::Mode.write }
      assert{ result.data[:b] = Dao::Mode.post }
    end
  end

## context
#
  test 'that calls have a shortcut to status' do
    api_class =
      assert{
        Dao.api do
          call(:foo){ status! 420 }
        end
      }
    api = assert{ api_class.new }
    result = assert{ api.call(:foo) }
    assert{ result.status =~ 420 }
  end

## results
#
  test 'that results can be created' do
    result = assert{ Dao::Result.new }
    assert{ result.path }
    assert{ result.status }
    assert{ result.errors }
    assert{ result.params }
    assert{ result.data }
  end

  test 'that results can be created with a path' do
    result = assert{ Dao::Result.new('/api/foo/bar') }
    assert{ result.path == '/api/foo/bar' }
  end

## paths
#
  test 'that simple paths can be contstructed/compiled' do
    path = assert{ Dao::Path.for('./api/../foo/bar')  }
    assert{ path =~ %r|^/| }
    assert{ path !~ %r|[.]| }
    assert{ path.params.is_a?(Hash) }
    assert{ path.keys.is_a?(Array) }
    assert{ path.pattern.is_a?(Regexp) }
  end

## routes
#
  test 'that an api has a list of routes' do
    api_class =
      assert{
        Dao.api do
        end
      }
    assert{ api_class.routes.is_a?(Array) }
  end

  test 'that routed endpoints call be declared' do
    api_class =
      assert{
        Dao.api do
          call('/users/:user_id/comments/:comment_id') do
            data.update(params)
          end
        end
      }
    api_class.new
  end

  test 'that routed methods can be called with embedded params' do
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
  test 'that apis can be documented via the api' do
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
  test 'that apis can alias methods' do
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
    assert{ api_class.new }
  end
end

