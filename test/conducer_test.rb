# -*- encoding : utf-8 -*-
Testing Dao::Conducer do
##
#
  context :teh_ctor do
  #
    testing 'conducers have a POLS .new method' do
      [
        {:key => :val, :array => [0,1,2]},
        {}
      ].each do |attributes|

        c = new_conducer(attributes)
        assert{ c.attributes =~ attributes }
      end
    end

  #
    testing 'models passed to .new are automatically tracked' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {}

      args = [user, post, comment, params]

      c = new_conducer(*args)

      assert{ c.models == [user, post, comment] }
      assert{ c.model == comment }
      assert{ c.model == c.conduces }

      assert{ c.conduces(post) }
      assert{ c.models == [user, comment, post] }
      assert{ c.model == post }
      assert{ c.model == c.conduces }
    end
  end

##
#
  context :teh_default_initialize do
  #
    testing 'that the last mode determines the lifecycle state when a models are passed in' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {}

      args = [user, post, comment, params]

      c = new_conducer(*args)

      %w( new_record? persisted? destroyed? ).each do |state|
        assert{ comment.send(state) == c.send(state) }
      end

      comment.new_record = false
      comment.persisted = true
      assert{ c.new_record? == false }
      assert{ c.persisted == true }
    end

  #
    testing 'that passed in models/params are sanely ker-sploded onto the attributes' do
      user = User.new :k => 1
      post = Post.new :k => 2
      comment = Comment.new :k => 3, :x => 4
      params = {:x => 5}

      args = [user, post, comment, params]

      c = new_conducer(*args)

      assert{ c.attributes[:user] =~ {:k => 1} }
      assert{ c.instance_variable_get('@user') == user }

      assert{ c.attributes[:post] =~ {:k => 2} }
      assert{ c.instance_variable_get('@post') == post }


      expected = {}
      expected.update :user => user.attributes
      expected.update :post => post.attributes
      expected.update comment.attributes
      expected.update params

      assert{ c.attributes =~ expected }
      assert{ c.instance_variable_get('@comment') == comment }
    end

  #
    testing 'that .new specilizes based on current action' do
      conducer_class =
        new_conducer_class do
          def initialize_for_new
            attributes.update(:new => Time.now)
          end
          def initialize_for_create
            attributes.update(:create => Time.now)
          end
          def initialize_for_edit
            attributes.update(:edit => Time.now)
          end
        end
        
      post = Post.new

      %w( new create edit ).each do |action|
        c = conducer_class.for(action, post)
        assert{ c.action == action }
        assert{ c.respond_to?("initialize_for_#{ action }") }
        assert{ c.attributes[action].is_a?(Time) }
        assert{ c.attributes.size == 1 }
      end
    end

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
  end

##
#
  context :teh_default_save do
  #
    testing 'is sane and based solely on the last model' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {:text => 'hai!', :user => {:params => 'are ignored'}, :post => {:params => 'are ignored'}}

      args = [user, post, comment, params]

      c = new_conducer(*args)

      assert{ comment[:text].nil? }
      assert{ c.save }
      assert{ comment.text == 'hai!' }
      assert{ comment[:user].nil? }
      assert{ comment[:post].nil? }
    end

  #
    testing 'halts when the conducer is invalid with errors' do
      conducer_class =
        new_conducer_class do
          validates_presence_of(:foo)
        end

      c = conducer_class.new

      assert{ !c.save }
      assert{ !c.valid? }
      assert{ !c.errors.empty? }
    end

  #
    testing 'halts when the model is invalid and relays errors' do
      post = Post.new
      post.errors[:foo] = 'is fucked'
      c = new_conducer(post)
      assert{ !c.save }
      assert{ c.errors[:foo] == Array(post.errors[:foo]) }
    end

  #
    testing 'raises a validation error on #save!' do
      post = Post.new
      post.errors[:foo] = 'is fucked'
      c = new_conducer(post)

      error = assert{ begin; c.save!; rescue Object => e; e; end; }

      assert{ error.errors == c.errors }
      assert{ error.errors[:foo] = Array(post.errors[:foo]) }
      assert{ c.errors[:foo] = Array(post.errors[:foo]) }
    end
  end

##
#
  context :validations do  
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

  #
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
  end

##
#
  context :forms do
  #
    testing 'that basic form helpers work' do
      c =
        assert{
          new_foo_conducer_class do
            validates_presence_of :bar
          end
        }

      o = assert{ c.new }
      assert{ !o.valid? } # make validations run...
      assert{ o.form }
      assert{ o.form.input(:foo) =~ /\<input/ }
      assert{ o.form.input(:foo) !~ /errors/ }
      assert{ o.form.textarea(:bar) =~ /\<textarea/ }
      assert{ o.form.textarea(:bar) =~ /errors/ }
    end
  end

##
#
  context :class_methods do
  #
    testing 'that base classes can be constructed and named' do
      new_foo_conducer_class()
    end

  #
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

  #
    testing '.model_name' do
      c = assert{ new_foo_conducer_class }
      assert{ c.model_name }
      o = assert{ c.new } 
      assert{ o.model_name }
    end
  end

##
#
  context :instance_methods do
    testing '#id' do
      [:_id, :id].each do |id_key|
        o = assert{ new_foo_conducer() }
        assert{ o.id.nil? }
        o.attributes.update(id_key => 42)
        assert{ o.id==42 }
        assert{ o.id = nil; true }
        assert{ !o.id }
        assert{ o.attributes[:id].nil? }
        assert{ o.attributes[:_id].nil? }
      end
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

  class Model
    {
      :new_record => true,
      :persisted => false,
      :destroyed => false,
    }.each do |state, value|
      class_eval <<-__
        attr_writer :#{ state }

        def #{ state }
          @#{ state } = #{ value } unless defined?(@#{ state })
          @#{ state }
        end

        def #{ state }?
          #{ state }
        end
      __
    end

    def initialize(attributes = {})
      self.attributes.update(attributes)
    end

    def attributes
      @attributes ||= Map.new
    end

    def [](key)
      attributes[key]
    end

    def []=(key, val)
      attributes[key] = val
    end

    def update_attributes(hash = {})
      hash.each{|k,v| attributes[k] = v }
    end

    def method_missing(method, *args, &block)
      re = /^([^=!?]+)([=!?])?$/imox
      matched, key, suffix = re.match(method.to_s).to_a
      
      case suffix
        when '=' then attributes.set(key, args.first)
        when '!' then attributes.set(key, args.size > 0 ? args.first : true)
        when '?' then attributes.has?(key)
        else
          attributes.has?(key) ? attributes.get(key) : super
      end
    end

    def inspect(*args, &block)
      "#{ self.class.name }( #{ attributes.inspect } )"
    end

    def errors
      @errors ||= Map.new
    end

    def valid?
      errors.empty?
    end

    def save
      return false unless valid?
      self.new_record = false
      self.persisted = true
      return true
    end

    def destroy
      true
    ensure
      self.new_record = false
      self.destroyed = true
    end
  end

  class User < Model
  end

  class Post < Model
  end

  class Comment < Model
  end
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')
  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
}
