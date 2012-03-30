# -*- encoding : utf-8 -*-
Testing Dao::Conducer do
## conducers
#
  testing 'that conducers have a POLS .new method' do
    [
      {:key => :val, :array => [0,1,2]},
      {}
    ].each do |attributes|

      c = new_conducer(attributes)
      assert{ c.attributes =~ attributes }
    end
  end

##
#
  testing 'that conducers can build a highly specialized .new method based on action' do
    c =
      new_conducer_class do
        def initialize(a, b, c, params)
          @a, @b, @c = a, b, c

          update_attributes(
            :foo => :bar
          )

          case action
            when 'new'
              update_attributes(:action => :new)
            when 'edit'
              update_attributes(:action => :edit)
            else
              update_attributes(:action => nil)
          end

          update_attributes(params)
        end
      end

    params = {:key => :val}

    %w( new edit ).each do |action|
      o = assert{ c.for(action, :a, :b, :c, params) }
      assert{ o.action == action }
      assert{ o.key == :val }
      assert{ o.foo == :bar }
      %w( a b c ).each{|var| assert{ o.instance_variable_get("@#{ var }") == var.to_sym } }
    end
  end

##
#
  testing 'that conducers can register handlers for setting deeply nested attributes' do
    c =
      new_conducer_class do
        def _update_attributes(attributes = {})
          attributes.each do |key, value|
            case Array(key).join('.')
              when 'user.first_name'
                set(key, value.to_s.upcase)
                return true
              else
                return false
            end
          end
        end
      end

    o = assert{ c.new :user => {:first_name => 'ara', :last_name => 'howard'} }
    assert{ o.user.first_name == 'ARA' }
    assert{ o.user.last_name == 'howard' }

    o = assert{ c.new :name => 'ara howard' }
    assert{ o.attributes.get(:name) == 'ara howard' }
  end

## classes 
#
  testing 'that base classes can be constructed and named' do
    new_foo_conducer_class()
  end

## validations
#
  testing 'that simple validations/errors work' do
    c =
      assert{
        new_foo_conducer_class do
          validates_presence_of :bar
          validates_presence_of :foo, :bar 
        end
      }

    o = assert{ c.new }
    assert{ !o.valid? }

    assert{ Array(o.errors.get(:bar)).size == 1 }
    assert{ Array(o.errors.get(:foo, :bar)).size == 1 }

    o.attributes.set :foo, :bar, 42
    assert{ !o.valid? }

    assert{ Array(o.errors.get(:bar)).size == 1 }
    assert{ Array(o.errors.get(:foo, :bar)).size == 0 }

    assert{ Array(o.errors.get(:foo, :bar)).empty? }
  end

  testing 'that validations are evaluated in the context of the object' do
    c =
      assert{
        new_foo_conducer_class do
          klass = self
          validates(:a){ klass == self.class }

          validates(:b){ value != 42.0 }

          def value() 42 end
        end
      }

    o = assert{ c.new }
    assert{ !o.valid? }
    assert{ o.errors.get(:a).empty? }
    assert{ !o.errors.get(:b).empty? }
  end

## form helpers
#
  testing 'that basic form helpers work' do
    c =
      assert{
        new_foo_conducer_class do
          validates_presence_of :bar
        end
      }

    o = assert{ c.new }
    assert{ o.form }
    assert{ o.form.input(:foo) =~ /\<input/ }
    assert{ o.form.textarea(:bar) =~ /\<textarea/ }
  end

##
#
  context 'class endpoint' do
    testing '.new' do
      c = assert{ new_foo_conducer_class }
      controller = assert{ Dao.mock_controller }

      check = proc do |args|
        params = args.detect{|arg| arg.is_a?(Hash)} || {}
        o = assert{ c.new(*args) }
        assert{ o.is_a?(Dao::Conducer) }
        assert{ o.attributes =~ params }
        assert{ o.controller.is_a?(ActionController::Base) }
      end

      [
        {},
        {:k => :v},
        nil,
      ].each do |params|
        check[ [params] ]
        check[ [controller, params] ]
        check[ [params, controller] ]
      end
    end

    testing '.model_name' do
      c = assert{ new_foo_conducer_class }
      assert{ c.model_name }
      o = assert{ c.new } 
      assert{ o.model_name }
    end
  end

  context 'instance endpoint' do
    testing '#to_param' do
      o = assert{ new_foo_conducer() }
      assert{ o.to_param.nil? }
      o.id = 42
      assert{ o.to_param }
    end

    testing '#errors' do
      o = assert{ new_foo_conducer() }
      assert{ o.errors.respond_to?(:[]) }
    end
  end

=begin
  context 'collections' do
    testing 'that subclasses have their own collection subclass' do
      c = assert{ new_foo_conducer_class }
      assert{ c::Collection }
      assert{ c.collection.new.is_a?(Array) }
      assert{ c.collection_class.ancestors.include?(Dao::Conducer::Collection) }
      assert{ c.collection.new.is_a?(Array) }
    end
  end
=end
  

protected
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

  prepare do
    $db = Dao::Db.new(:path => 'test/db.yml')
    Dao::Db.instance = $db
    collection = $db['foos']
    %w( a b c ).each do |name|
      collection.save(
        :name => name, :created_at => Time.now.to_f, :a => %w( x y z ), :h => {:k => :v}
      )
    end
  end

  cleanup do
    $db = Dao::Db.new(:path => 'test/db.yml')
    $db.rm_f
  end

  def db
    $db
  end

  def collection
    $db[:foos]
  end
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')
  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
}
