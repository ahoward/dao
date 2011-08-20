Testing 'Dao.parse' do
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

  testing 'that params are auto-parsed if they need to be ' do
    assert{
      api_class =
        Dao.api do
          call('/foobar'){
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

  testing 'that params are auto-parsed if they were form encoded' do
    assert{
      api_class =
        Dao.api do
          call('/foobar'){
            data.update(params)
          }
        end
      api = api_class.new

      form_encoded = {
        'dao' => {
          '/foobar' => {
            'a' => 40,
            'b' => 2,
            'array,0' => 40,
            'array,1' => 2,
            'hash,k' => 'v',
            'hash,x' => 'y'
          }
        }
      }

      result = assert{ api.call('/foobar', form_encoded) }
      assert{ result.data =~ {'a' => 40, 'b' => 2, 'array' => [40,2], 'hash' => {'k' => 'v', 'x' => 'y'}} }

      result = assert{ api.call('/foobar', 'key' => 'val') }
      assert{ result.data =~ {'key' => 'val'} }
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
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')

  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
  require File.join(testdir, 'helper')
}
