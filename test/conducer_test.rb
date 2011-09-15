Testing Dao::Conducer do
##
#
  testing 'that base classes can be constructed and named' do
    new_foo_conducer_class()
  end

##
#
  testing 'that basic validations/errors work' do
    c =
      assert{
        new_foo_conducer_class do
          validates_presence_of :bar
          validates_presence_of :foo, :bar 
        end
      }

    o = assert{ c.new }
    assert{ !o.valid? }

    assert{ !Array(o.errors.get(:bar)).empty? }
    assert{ !Array(o.errors.get(:foo, :bar)).empty? }

    o.attributes.set :foo, :bar, 42
    assert{ !o.valid? }

    assert{ Array(o.errors.get(:foo, :bar)).empty? }
  end

##
#
  testing 'that basic form elements work' do
    c =
      assert{
        new_foo_conducer_class do
          validates_presence_of :bar
        end
      }

    o = assert{ c.new }
    assert{ o.form }
    assert{ o.form.input(:foo) }
    assert{ o.form.input(:bar) }
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

    testing '.all' do
      c = assert{ new_foo_conducer_class }
      assert{ c.all().is_a?(Array) }
      assert{ c.all(nil).is_a?(Array) }
      assert{ c.all({}).is_a?(Array) }
    end

    testing '.find' do
      c = assert{ new_foo_conducer_class }
      o = assert{ c.new }
      assert{ c.find(o.id).is_a?(Dao::Conducer) }
    end

    testing '.model_name' do
      c = assert{ new_foo_conducer_class }
      assert{ c.model_name }
      o = assert{ c.new } 
      assert{ o.model_name }
    end
  end

  context 'current' do
    testing 'class and instance endpoints' do
      c = assert{ new_foo_conducer_class }
      o = c.new
      %w(
        current_controller
        current_request
        current_response
        current_session
        current_user
      ).each do |method|
        assert{ o.respond_to?(method) }
        assert{ c.respond_to?(method) }
      end
    end
  end

  context 'instance endpoint' do
    testing '#save' do
      params = {:k => :v}
      o = assert{ new_foo_conducer(params) }
      assert{ o.save }
      id = assert{ o.id }
      assert{ db.foos.find(id)[:k] == o.attributes[:k] }
      assert{ id == o.id }
      assert{ o.attributes =~ params.merge(:id => id) }
    end

    testing '#update_attributes' do
      params = {:k => :v}
      o = assert{ new_foo_conducer(params) }
      t = Time.now
      assert{ o.update_attributes :t => t }
      assert{ o.save }
      id = assert{ o.id }
      assert{ db.foos.find(id).id == o.id }
      assert{ db.foos.find(id) =~ params.merge(:id => id, :t => t) }
    end

    testing '#destroy' do
      params = {:k => :v}
      o = assert{ new_foo_conducer(params) }
      assert{ o.save }
      id = assert{ o.id }
      assert{ db.foos.find(id).id == o.id }
      assert{ o.destroy }
      assert{ db.foos.find(id).nil? }
    end

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

  

protected
  def new_foo_conducer_class(&block)
    name = 'FooConducer'
    c = assert{ Class.new(Dao::Conducer){ self.name = name; crud! } }
    assert{ c.name == 'FooConducer' }
    assert{ c.model_name == 'Foo' }
    assert{ c.table_name == 'foos' && c.collection_name == 'foos' }
    assert{ c.module_eval(&block); true } if block
    c
  end

  def new_foo_conducer(*args, &block)
    assert{ new_foo_conducer_class(&block).new(*args) }
  end

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
