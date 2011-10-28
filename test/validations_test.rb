Testing Dao::Validations do
## status
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

## errors
#
  testing 'that clear does not drop sticky errors' do
    errors = Dao::Errors.new
    errors.add! 'sticky', 'error'
    assert{ errors['sticky'].first.sticky? }
    errors.add 'not-sticky', 'error'
    errors.clear
    assert{ errors['sticky'].first == 'error' }
    assert{ errors['not-sticky'].empty? }
  end

  testing 'that clear! ***does*** drop sticky errors' do
    errors = Dao::Errors.new
    errors.add! 'sticky', 'error'
    errors.add 'not-sticky', 'error'
    errors.clear!
    assert{ errors['sticky'].empty? }
    assert{ errors['not-sticky'].empty? }
  end

  testing 'that global errors are sticky' do
    errors = Dao::Errors.new
    global = Dao::Errors::Global
    errors.add! 'global-error'
    errors.clear
    assert{ errors[global].first == 'global-error' }
    errors.clear!
    assert{ errors[global].empty? }
  end

## validations
#
  testing 'that simple validations work' do
    params = Dao::Params.new
    assert{ params.validates(:password){|password| password=='haxor'} }
    params.set(:password, 'haxor')
    assert{ params.valid? }
  end

  testing 'that validations have some syntax sugar' do
    return :pending

    assert{
      api_class =
        Dao.api do
          endpoint('/foobar'){
            validates(:a)
            validate!
          }
        end
      api = api_class.new

      result = assert{ api.call('/foobar', 'a' => true) }
      assert{ result.status.ok? }

      result = assert{ api.call('/foobar') }
      assert{ result.errors.size==1 }
      assert{ !result.status.ok? }
    }
  end

  testing 'that validations use instance_exec' do
    return :pending

    a, b = nil

    api_class =
      Dao.api do
        endpoint('/foobar'){
          params.validate(:a){ b = get(:b) }
          params.validate(:b){ a = get(:a) }
          validate!
        }
      end
    api = api_class.new

    result = assert{ api.call('/foobar', 'a' => 40, 'b' => 2) }
    assert{ result.status.ok? }
    assert{ a == 40 }
    assert{ b == 2 }
  end

  testing 'simple validates_confirmation_of' do
    return :pending

    api_class =
      Dao.api do
        endpoint('/foobar'){
          params.validates_as_email(:email)
          params.validates_confirmation_of(:email)
          validate!
        }
      end
    api = api_class.new

    result = assert{ api.call('/foobar', 'email' => 'ara.t.howard@gmail.com', 'email_confirmation' => 'ara.t.howard@gmail.com') }
    assert{ result.status.ok? }
    assert{ result.errors.empty? }

    result = assert{ api.call('/foobar', 'email' => 'ara.t.howard@gmail.com', 'email_confirmation' => 'ara@dojo4.com') }
    assert{ !result.status.ok? }
    assert{ !result.errors.empty? }
  end

## validating
#
  testing 'that validations can be cleared and do not clobber manually added errors' do
    params = Dao::Params.new
    errors = params.errors

    assert{ params.validates(:email){|email| email.to_s.split(/@/).size == 2} }
    assert{ params.validates(:password){|password| password == 'pa$$w0rd'} }

    params.set(:email => 'ara@dojo4.com', :password => 'pa$$w0rd')
    assert{ params.valid? }

    params.set(:password => 'haxor')
    assert{ !params.valid?(:validate => true) }

    errors.add(:name, 'ara')
    assert{ not params.valid? }
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
