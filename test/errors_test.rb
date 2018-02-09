# -*- encoding : utf-8 -*-
require 'test_helper'
class DaoErrorsTest < Dao::TestCase

  test 'that conducer-less error objects scopes keys in a generic fashion' do
    e = Dao::Errors.new

    e.add 'is fucked'
    e.add 'foo is fucked'

    actual = e.to_text 

    expected = <<-__
      ---
      global:
      - is fucked
      - foo is fucked
    __

    assert compress(actual) == compress(expected)
  end

  test 'that conducer-based error objects scope keys in a model_name based fashion' do
    c = new_foo_conducer

    e = c.errors 

    e.add 'is fucked'
    e.add 'foo is fucked'
    e.add :first_name, 'is fucked'
    e.add :last_name, 'is fucked'

    actual = e.to_text

    expected = <<-__
      ---
      foo:
      - is fucked
      - foo is fucked
      foo.first_name:
        - is fucked
      foo.last_name:
        - is fucked
    __

    assert compress(actual) == compress(expected)
  end

=begin
  test 'that `nested` errors `nest`' do
    e = Dao::Errors.new

    e.relay 'foo.bar' => 'is fucked'

p e.to_hash
    assert e.to_hash == {'foo' => {'bar' => 'is fucked'}} 
  end
=end


protected
  def compress(string)
    string.to_s.gsub(/\s/, '')
  end
  def new_foo_conducer_class(&block)
    const = :FooConducer
    Object.send(:remove_const, const) if Object.send(:const_defined?, const)
    name = const.to_s
    c = assert{ Class.new(Dao::Conducer){ self.name = name } }
    Object.send(:const_set, const, c)
    assert{ c.name == 'FooConducer' }
    assert{ c.model_name == 'Foo' }
    assert{ c.table_name == 'foos' && c.collection_name == 'foos' }
    assert{ c.class_eval(&block); true } if block
    c
  end
  alias_method :new_conducer_class, :new_foo_conducer_class

  def new_foo_conducer(*args, &block)
    assert{ new_foo_conducer_class(&block).new(*args) }
  end
  alias_method :new_conducer, :new_foo_conducer
end
