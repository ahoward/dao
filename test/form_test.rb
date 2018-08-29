# -*- encoding : utf-8 -*-
require_relative 'test_helper'
class DaoFormTest < ::Dao::TestCase
  test '.new' do
    form = new_form() 
    form = new_named_form() 
  end

  test 'name_for' do
    assert{ Dao::Form.name_for(:foo, :a, :b) == 'dao[foo][a.b]' }
    assert{ new_form.name_for(:a, :b) == 'dao[form][a.b]' }
    assert{ new_named_form.name_for(:a, :b) == 'dao[name][a.b]' }
    assert{ new_named_form(:foo).name_for(:a, :b) == 'dao[foo][a.b]' }
  end

  test 'scope_for' do
    form = new_form() 

    assert do
      html = form.input(:bar)
      scmp(
        html,
        '<input type="text" name="dao[form][bar]" class="dao" id="form--bar"/>'
      )
    end

    assert do
      form.scope_for(:foo) do
        html = form.input(:bar)
        scmp(
          html,
          '<input type="text" name="dao[form][foo.bar]" class="dao" id="form--foo-bar"/>'
        )
      end
    end

    assert do
      html = form.input(:bar)
      scmp(
        html,
        '<input type="text" name="dao[form][bar]" class="dao" id="form--bar"/>'
      )
    end
  end

  test 'Form#select' do
  #
    form = new_form() 
    form.attributes.set :key => 42 

  #
    html = assert{ form.select(:key) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"> </select>'
      )
    end

  #
    html = assert{ form.select(:key, :values => %w( a b c )) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="a">a</option><option value="b">b</option><option value="c">c</option></select>'
      )
   end

  #
    html = assert{ form.select(:key, :values => %w( A B C ).zip([1,2,3])) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="1">A</option><option value="2">B</option><option value="3">C</option></select>'
      )
   end

  #
    html = assert{ form.select(:key, :values => %w( a b c ), :blank => true) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option></option><option value="a">a</option><option value="b">b</option><option value="c">c</option></select>'
      )
   end

  #
    html = assert{ form.select(:key, :values => %w( a b c ), :blank => nil) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option></option><option value="a">a</option><option value="b">b</option><option value="c">c</option></select>'
      )
   end

  #
    html = assert{ form.select(:key, :values => %w( a b c ), :blank => 42) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="">42</option><option value="a">a</option><option value="b">b</option><option value="c">c</option></select>'
      )
   end

  #
    html = assert{ form.select(:key, :values => %w( a b c ), :blank => false) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="a">a</option><option value="b">b</option><option value="c">c</option></select>'
      )
   end

  #
    html = assert{ form.select(:key, :values => %w( a b c ), :selected => :b) }
    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="a">a</option><option value="b" selected>b</option><option value="c">c</option></select>'
      )
    end

  #
    block = proc do |content, value, selected_value|
      is_selected = value.to_s == selected_value.to_s
      [content, value, is_selected]
    end

    html = assert{ form.select(:key, :values => [41, 42, 43], &block) }

    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="41">41</option><option value="42" selected>42</option><option value="43">43</option></select>'
      )
    end

  #
    block = proc do |content, value|
      is_selected = value.to_s == '42'
      [content, value, is_selected]
    end

    html = assert{ form.select(:key, :values => [41, 42, 43], &block) }

    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="41">41</option><option value="42" selected>42</option><option value="43">43</option></select>'
      )
    end

  #
    block = proc do |content, value|
      is_selected = value.to_s == '42'
      { :content => content, :value => value, :selected => is_selected }
    end

    html = assert{ form.select(:key, :values => [41, 42, 43], &block) }

    assert do
      scmp(
        html,
        '<select name="dao[form][key]" class="dao" id="form--key"><option value="41">41</option><option value="42" selected>42</option><option value="43">43</option></select>'
      )
    end
  end

protected
  def new_form
    #assert{ Dao::Form.new }
    Dao::Form.new
  end

  def new_named_form(name = 'name')
    object = Object.new
    class << object
      %w[ name attributes errors ].each{|attr_name| attr_accessor(attr_name)}
      attr_accessor :name
    end
    object.name = name
    object.attributes = Map.new
    object.errors = Dao::Errors.new
    assert{ Dao::Form.new(object) }
  end
end
