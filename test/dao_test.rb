testdir = File.dirname(File.expand_path(__FILE__))
rootdir = File.dirname(testdir)
libdir = File.join(rootdir, 'lib')

require File.join(libdir, 'dao')
require File.join(testdir, 'testing')
require File.join(testdir, 'helper')


Testing Dao do
# api
#
  testing 'that an api class for your application can be built using a simple dsl' do
    assert{
      api_class =
        Dao.api do
          ### dsl
        end
    }
  end

  testing 'that apis can have callable interfaces added to them which accept params and return results' do
    captured = []

    api_class =
      assert{
        Dao.api do
          interface(:foo) do |params, result|
            captured.push(params, result)
          end
        end
      }
    api = assert{ api_class.new }
    result = assert{ api.call(:foo, {}) }
    assert{ result.is_a?(Hash) }
  end

  testing 'that interfaces are automatically called according to arity' do
    api = assert{ Class.new(Dao.api) }
    assert{ api.class_eval{ interface(:zero){|| result.update :args => [] } } }
    assert{ api.class_eval{ interface(:one){|a| result.update :args => [a]} } }
    assert{ api.class_eval{ interface(:two){|a,b| result.update :args => [a,b]} } }

    assert{ api.new.call(:zero).args.size == 0 }
    assert{ api.new.call(:one).args.size == 1 }
    assert{ api.new.call(:two).args.size == 2 }
  end

  testing 'that interfaces have an auto-vivifying params/result' do
    api = assert{ Class.new(Dao.api) }
    assert{ api.class_eval{ interface(:foo){ params; result; } } }
    result = assert{ api.new.call(:foo) }
    assert{ result.path.to_s =~ /foo/ }
  end

# results
#
  testing 'that results can be created' do
    result = assert{ Dao::Result.new }
    assert{ result.path }
    assert{ result.status }
    assert{ result.data }
    assert{ result.errors }
    assert{ result.validations }
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

# status
#
  testing 'Status.for' do
    assert{ Dao::Status.for(:unauthorized).code == 401 }
    assert{ Dao::Status.for(:UNAUTHORIZED).code == 401 }
    assert{ Dao::Status.for('unauthorized').code == 401 }
    assert{ Dao::Status.for('UNAUTHORIZED').code == 401 }
    assert{ Dao::Status.for('Unauthorized').code == 401 }
    assert{ Dao::Status.for(:Unauthorized).code == 401 }
    assert{ Dao::Status.for(:No_Content).code == 204 }
    assert{ Dao::Status.for(:no_content).code == 204 }
  end

  testing 'status equality operator' do
    s = Dao::Status.for(401)
    assert{ s == :unauthorized }
    assert{ s == 401 }
    assert{ s != Array.new }
  end

# parser
#
  testing 'parsing a simple hash by key' do
    params = {
      'key(a)' => 40,
      'key(b)' => 2
    }
    parsed = Dao.parse(:key, params)
    expected = {'a' => 40, 'b' => 2}
    assert{ parsed =~ expected }
  end

  testing 'parsing a nested hash by key' do
    params = {
      'key(a,x)' => 40,
      'key(a,y)' => 2
    }
    parsed = Dao.parse(:key, params)
    expected = {'a' => {'x' => 40, 'y' => 2}} 
    assert{ parsed =~ expected }
  end

  testing 'parsing a deeply nested hash by key' do
    params = {
      'key(a,b,x)' => 40,
      'key(a,b,y)' => 2
    }
    parsed = Dao.parse(:key, params)
    expected = {'a' => {'b' => {'x' => 40, 'y' => 2}}} 
    assert{ parsed =~ expected }
  end

  testing 'that params are auto-parsed if the api detects that they need to be ' do
    assert{
      api_class =
        Dao.api do
          interface('/foobar'){
            data.update(params)
          }
        end
      api = api_class.new

      result = assert{ api.call('/foobar', 'key' => 'val') }
      assert{ result.data =~ {'key' => 'val'} }

      result = assert{ api.call('/foobar', '/foobar(key)' => 'val', '/foobar(a,0)' => 42, '/foobar(a,1)' => 42.0) }
      assert{ result.data =~ {'key' => 'val', 'a' => [42, 42.0]} }
    }
  end

  testing 'that parsing folds in top level keys by default' do
    params = {
      'key(a)' => 40,
      'key(b)' => 2,
      'a' => 'clobbered',
      'b' => 'clobbered',
      'c' => 42
    }
    parsed = Dao.parse(:key, params)
    expected = {'a' => 40, 'b' => 2, 'c' => 42}
    assert{ parsed =~ expected }
  end

  testing 'that parsing can have folding turned off' do
    params = {
      'key(a)' => 40,
      'key(b)' => 2,
      'a' => 'clobbered',
      'b' => 'clobbered',
      'c' => 42
    }
    parsed = Dao.parse(:key, params, :fold => false)
    expected = {'a' => 40, 'b' => 2}
    assert{ parsed =~ expected }
  end

  testing 'that parse folding can be white list-ly selective' do
    params = {
      'key(a)' => 40,
      'key(b)' => 2,
      'a' => 'clobbered',
      'b' => 'clobbered',
      'c' => 42,
      'd' => 'not included...'
    }
    parsed = Dao.parse(:key, params, :include => [:c])
    expected = {'a' => 40, 'b' => 2, 'c' => 42}
    assert{ parsed =~ expected }
  end

  testing 'that parse folding can be black list-ly selective' do
    params = {
      'key(a)' => 40,
      'key(b)' => 2,
      'a' => 'clobbered',
      'b' => 'clobbered',
      'c' => 42,
      'd' => 'rejected...',
      'e' => 'rejected...'
    }
    parsed = Dao.parse(:key, params, :except => [:d, :e])
    expected = {'a' => 40, 'b' => 2, 'c' => 42}
    assert{ parsed =~ expected }
  end

# errors.rb
#
  testing 'that clear does not drop sticky errors' do
    errors = Dao::Errors.new
    errors.add! 'sticky', 'error'
    errors.add 'not-sticky', 'error'
    errors.clear
    assert{ errors['sticky'].first == 'error' }
    assert{ errors['not-sticky'].nil? }
  end

  testing 'that clear! ***does*** drop sticky errors' do
    errors = Dao::Errors.new
    errors.add! 'sticky', 'error'
    errors.add 'not-sticky', 'error'
    errors.clear!
    assert{ errors['sticky'].nil? }
    assert{ errors['not-sticky'].nil? }
  end

  testing 'that global errors are sticky' do
    errors = Dao::Errors.new
    global = Dao::Errors::Global
    errors.add! 'global-error'
    errors.clear
    assert{ errors[global].first == 'global-error' }
    errors.clear!
    assert{ errors[global].nil? }
  end

# validations
#
  testing 'that simple validations work' do
    result = Dao::Result.new
    assert{ result.validates(:password){|password| password=='haxor'} }
    result.data.set(:password, 'haxor')
    assert{ result.valid? }
  end

  testing 'that validations have some syntax sugar' do
    assert{
      api_class =
        Dao.api do
          interface('/foobar'){
            result.validates(:a)
            params.validate(:b)
            validates(:c)
          }
        end
      api = api_class.new

      result = assert{ api.call('/foobar', 'a' => true, 'b' => true, 'c' => true) }
    }
  end

# validating
#
  testing 'that validations can be cleared and do not clobber manually added errors' do
    result = Dao::Result.new
    data = result.data
    errors = result.errors

    assert{ result.validates(:email){|email| email.to_s.split(/@/).size == 2} }
    assert{ result.validates(:password){|password| password == 'pa$$w0rd'} }

    data.set(:email => 'ara@dojo4.com', :password => 'pa$$w0rd')
    assert{ result.valid? }

    data.set(:password => 'haxor')
    assert{ !result.valid?(:validate => true) }

    errors.add(:name, 'ara')
    assert{ not result.valid? }
  end

# doc
#
  testing 'that apis can be documented via the api' do
    api_class =
      assert {
        Dao.api {
          description 'foobar'
          doc 'signature' => {'read' => '...', 'write' => '...'} 
          interface('/barfoo'){}
        }
      }
    api_class_index = assert{ api_class.index.is_a?(Hash) }
    api = assert{ api_class.new }
    api_index = assert{ api.index.is_a?(Hash) }
    assert{ api_class_index==api_index }
  end

=begin

# cloning
#
  testing 'simple cloning' do
    data = Dao.data(:foo)
    clone = assert{ data.clone }
    assert{ data.path == clone.path }
    assert{ data.errors == clone.errors }
    assert{ data.errors.object_id != clone.errors.object_id }
    assert{ data.validations == clone.validations }
    assert{ data.validations.object_id != clone.validations.object_id }
    assert{ data.form != clone.form }
    assert{ data.form.object_id != clone.form.object_id }
    assert{ data.status == clone.status }
    assert{ data.status.object_id != clone.status.object_id }
    assert{ data == clone }
  end

=end

    def hash_equal(a, b)
      array = lambda{|h| h.to_a.map{|k,v| [k.to_s, v]}.sort}
      array[a] == array[b]
    end
end
