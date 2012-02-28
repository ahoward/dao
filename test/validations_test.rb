# -*- encoding : utf-8 -*-
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
  testing 'that errors can relay from other each-able sources' do
    errors = Dao::Errors.new

    source =
      assert do
        c = Class.new Hash do
          def self.human_attribute_name(*a) a.first.to_s end
        end
        m = c.new 
        e = ActiveModel::Errors.new(m)
        e.add('foo', 'is fucked')
      end

    assert{ errors.relay(source) }

    assert{ errors.on(:foo) }
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

  testing 'that validations use instance_exec - as god intended' do
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
  testing 'that validations clear only that which they know about' do
    params = Dao::Params.new
    errors = params.errors

    assert{ params.validates(:email){|email| email.to_s.split(/@/).size == 2} }
    assert{ params.validates(:password){|password| password == 'pa$$w0rd'} }

    params.set(:email => 'ara@dojo4.com')


    params.set(:password => 'haxor')
    assert{ !params.valid? }
    assert{ !params.errors.on(:password).empty? }

    params.set(:password => 'pa$$w0rd')
    assert{ params.valid? }
    assert{ params.errors.on(:password).empty? }


    params.errors.add 'foo', 'is fucked'


    params.set(:password => 'haxor')
    assert{ !params.valid? }
    assert{ !params.errors.on(:password).empty? }
    assert{ !params.errors.on(:foo).empty? }


    params.set(:password => 'pa$$w0rd')
    assert{ !params.valid? }
    assert{ params.errors.on(:password).empty? }
    assert{ !params.errors.on(:foo).empty? }
  end

## stand alone validations
#
  testing 'that validations can be used standalone' do
    attributes = {
      :email => 'ara@dojo4.com',
      :password => 'pa$$w0rd'
    }

    v = assert{ Dao::Validations.for(attributes) }

    assert{ v.validates(:email){|email| email.to_s.split(/@/).size == 2} }
    assert{ v.validates(:password){|password| password == 'pa$$w0rd'} }
    assert{ v.valid? }

    v.set(:password => 'haxor')
    assert{ !v.valid? }
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
