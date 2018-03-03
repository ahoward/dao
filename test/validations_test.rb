# -*- encoding : utf-8 -*-
require 'test_helper'
class DaoValidationsTest < ::Dao::TestCase
## status
#
  test 'Status.for' do
    assert{ Dao::Status.for(:unauthorized).code == 401 }
    assert{ Dao::Status.for(:UNAUTHORIZED).code == 401 }
    assert{ Dao::Status.for('unauthorized').code == 401 }
    assert{ Dao::Status.for('UNAUTHORIZED').code == 401 }
    assert{ Dao::Status.for('Unauthorized').code == 401 }
    assert{ Dao::Status.for(:Unauthorized).code == 401 }
    assert{ Dao::Status.for(:No_Content).code == 204 }
    assert{ Dao::Status.for(:no_content).code == 204 }
  end

  test 'status equality operator' do
    s = Dao::Status.for(401)
    assert{ s == :unauthorized }
    assert{ s == 401 }
    assert{ s != Array.new }
  end

## errors
#
  test 'that errors can relay from other each-able sources' do
    errors = Dao::Errors.new

    messages = [
      'foo is fucked',
      'foo is fucked twice',
    ]

    model =
      assert do
        model_class = Class.new(Hash) do
          def self.human_attribute_name(*args)
            args.first.to_s
          end

          def errors
            @errors ||= ActiveModel::Errors.new(self)
          end
        end
        m = model_class.new
        messages.each{|message| m.errors.add(:foo, message)}
        m
      end

    [model, model.errors].each do |source|
      assert{ errors.relay(source) }
      assert{ errors.on(:foo) == messages }
      assert{ errors.clear }

      assert{ errors.relay(source, :key => :bar) }
      assert{ errors.on(:bar) == messages }
      assert{ errors.clear }

      assert{ errors.relay(source, :prefix => [:a, :b, :c]) }
      assert{ errors.on(:a, :b, :c, :foo) == messages }
      assert{ errors.clear }
    end
  end

## validations
#
  test 'that simple validations work' do
    params = Dao::Params.new
    assert{ params.validates(:password){|password| password=='haxor'} }
    params.set(:password, 'haxor')
    assert{ params.valid? }
  end

  test 'that validations have some syntax sugar' do
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

  test 'that validations use instance_exec - as god intended' do
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

  test 'simple validates_confirmation_of' do
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
  test 'that validations clear only that which they know about' do
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
  test 'that validations can be used standalone' do
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

## prefixed validations
#
  test 'nested validations' do
  #
    attributes = {
      :list => [
        {:k => :v},
        {:K => :V}
      ]
    }

  #
    v = assert{ Dao::Validations.for(attributes) }
    ran = 0
    assert{
      v.validates :list do |list|
        list.size.times do |i|
          validates i do
            ran += 1
          end
        end
        true
      end
    }
    assert{ v.run_validations }
    assert{ ran == 2 }

  #
    v = assert{ Dao::Validations.for(attributes) }
    ran = 0
    assert{
      v.validates :list do |list|
        list.each_with_index do |item, index|
          item.each do |k,v|
            validates index, k do |value|
              ran += 1
              value==v
            end
          end
        end
        true
      end
    }
    assert{ v.run_validations }
    assert{ ran == 2 }

  #
    v = assert{ Dao::Validations.for(attributes) }
    ran = 0
    assert{
      v.validates_each :list do |item|
        item.each do |k,v|
          validates k do |value|
            ran += 1
            value==v
          end
        end
        true
      end
    }
    assert{ v.run_validations }
    assert{ ran == 2 }

  #
    attributes = {
      :users => [
        {
          :name => 'jane doe',

          :roles => [
            { :name => :admin },
            { :name => :user },
          ]
        },
        {
          :name => 'john doe',

          :roles => [
            { :name => :user },
          ]
        }
      ]
    }

    v = assert{ Dao::Validations.for(attributes) }
    ran = 0
    assert{

      v.validates_each :users do
        validates_presence_of :name
        validates_presence_of :missing

        validates :name do |name|
          ran += 1
          name =~ /doe/
        end

        validates_each :roles do |role|
          validates_presence_of :missing

          validates :name do |name|
            ran += 1
            name =~ /admin|user/
          end
        end
      end

    }
    assert{ v.run_validations }
    assert{ ran == 5 }
    assert{ v.errors.on(:users, 0, :name).blank? }
    assert{ v.errors.on(:users, 1, :name).blank? }

    assert{ !v.errors.on(:users, 0, :missing).blank? }
    assert{ !v.errors.on(:users, 1, :missing).blank? }

    assert{ !v.errors.on(:users, 0, :roles, 0, :missing).blank? }
    assert{ !v.errors.on(:users, 0, :roles, 1, :missing).blank? }
    assert{ !v.errors.on(:users, 1, :roles, 0, :missing).blank? }
  end
end
