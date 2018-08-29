# -*- encoding : utf-8 -*-
require_relative 'test_helper'

class Dao::ConducerTest < Dao::TestCase
##
#
  context :teh_ctor do
  #
    test 'conducers have a POLS .new method' do
      [
        {:key => :val, :array => [0,1,2]},
        {}
      ].each do |attributes|
        c = new_conducer(attributes)
        assert{ c.attributes =~ attributes }
      end
    end

  #
    test 'models passed to .new are automatically tracked' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {}

      args = [comment, post, user, params]

      c = new_conducer(*args)

      assert{ c.models == [comment, post, user] }
      assert{ c.model == comment }
      assert{ c.model == c.conduces }
    end

  #
    test 'that the conduced model can be declared at the class level' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {}

      args = [comment, post, user, params]

      c = new_conducer(*args){ conduces User }

      assert{ c.models == [comment, post, user] }
      assert{ c.model == user }
      assert{ c.model == c.conduces }
    end

  #
    test 'that the conduced model can be declared at the instance level' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {}

      args = [comment, post, user, params]

      c = new_conducer(*args)

      c.conduces(user)

      assert{ c.models == [user, comment, post] }
      assert{ c.model == user }
      assert{ c.model == c.conduces }
    end
  end

##
#
  context :teh_default_initialize do
  #
    test 'that the last mode determines the lifecycle state when a models are passed in' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {}

      args = [comment, post, user, params]

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
    test 'that passed in models/params are sanely ker-sploded onto the attributes' do
      user    = User.new :k => 1
      post    = Post.new :k => 2
      comment = Comment.new :k => 3, :x => 4
      params  = {:x => 5}

      args = [comment, post, user, params]

      c = new_conducer(*args)

      assert{ c.attributes[:user] =~ {:k => 1} }
      assert{ c.instance_variable_get('@user') == user }

      assert{ c.attributes[:post] =~ {:k => 2} }
      assert{ c.instance_variable_get('@post') == post }

      expected = Map.new
      expected.add :user => user.attributes
      expected.add :post => post.attributes
      expected.add comment.attributes
      expected.add params

      assert{ c.attributes =~ expected }
      assert{ c.instance_variable_get('@comment') == comment }
    end

  #
    test 'that .new specialises based on current action' do
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
    test 'that conducers can build a highly specialized .new method based on action' do
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

 #
    test 'that conducers *fold* in attributes' do
      c = new_conducer

      assert{ c.update_attributes :key => {:a => :b} }
      assert{ c.update_attributes :key => {:nested => {:a => :b}} }
      assert{ c.attributes =~ {:key => {:a => :b, :nested => {:a => :b}}}  }
    end

##
#
  context :teh_default_save do
  #
    test 'is sane and based solely on the last model' do
      user = User.new
      post = Post.new
      comment = Comment.new
      params = {:text => 'hai!', :user => {:params => 'are ignored'}, :post => {:params => 'are ignored'}}

      args = [comment, post, user, params]

      c = new_conducer(*args)

      assert{ comment[:text].nil? }
      assert{ c.save }
      assert{ comment.text == 'hai!' }
      assert{ comment[:user].nil? }
      assert{ comment[:post].nil? }
    end

  #
    test 'halts when the conducer is invalid with errors' do
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
    test 'halts when the model is invalid and relays errors' do
      post = Post.new
      post.errors[:foo] = 'is fucked'
      c = new_conducer(post)
      assert{ !c.save }
      assert{ c.errors[:foo] == Array(post.errors[:foo]) }
    end

  #
    test 'raises a validation error on #save!' do
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
    test 'that simple validations/errors work' do
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
    test 'that validations are evaluated in the context of the object' do
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

  #
    test 'that validates_each werks at the class and instance level' do
      conducer_class =
        new_conducer_class do
          validates_each :a do |item|
            validated.push(item)
            true
          end

          def save
            validates_each :b do |item|
              validated.push(item)
              true
            end
            return valid?
          end

          def validated
            @validated ||= []
          end
        end

      a = %w( a b c )
      b = %w( 1 2 3 )

      c = assert{ conducer_class.new(:a => a, :b => b) }
      assert{ c.run_validations }
      assert{ c.validated == %w( a b c ) }

    
      c = conducer_class.new(:a => a, :b => b)
      assert{ c.save }
      assert{ c.validated == %w( a b c 1 2 3 ) }
    end
  end

##
#
  context :forms do
  #
    test 'that basic form helpers work' do
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
    test 'that base classes can be constructed and named' do
      new_foo_conducer_class()
    end

  #
    test '.new' do
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
    test '.model_name' do
      c = assert{ new_foo_conducer_class }
      assert{ c.model_name }
      o = assert{ c.new } 
      assert{ o.model_name }
    end
  end

##
#
  context :instance_methods do
    test '#id' do
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

    test '#to_param' do
      o = assert{ new_foo_conducer() }
      assert{ o.to_param.nil? }
      o.id = 42
      assert{ o.to_param }
    end

    test '#errors' do
      o = assert{ new_foo_conducer() }
      assert{ o.errors.respond_to?(:[]) }
    end

=begin
    test 'that conducers can register handlers for setting deeply nested attributes' do
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
=end
  end


##
#
  context :teh_mount do
  #
    test 'that mounted objects can be declared at the class level' do
      conducer_class =
        new_conducer_class do
          mount Dao::Upload, :a, :b, :placeholder => '/images/foo.jpg'
        end

      assert{ !conducer_class.mounted.empty? }

      c = conducer_class.new

      assert{ c.mounted.first.is_a?(Dao::Upload) }
      assert{ c.mounted.first._key.join('.') == 'a.b' }
      assert{ c.mounted.first._value.nil? }
    end

  #
    test 'that mounted objects replace their location in attributes' do
      conducer_class =
        new_conducer_class do
          mount Dao::Upload, :a, :b, :placeholder => '/images/foo.jpg'
        end

      path = __FILE__
      up = Upload.new(path)

      c = conducer_class.new( :a => {:b => {:file => up}} )

      upload = assert{ c.get(:a, :b) }

      assert{ upload.is_a?(Dao::Upload) }
      assert{ test(?f, upload._value) }
    end

  #
    test 'that the default save uses the mounted _value and _clears it' do
begin
$pry=true
      conducer_class =
        new_conducer_class do
          mount Dao::Upload, :up, :placeholder => '/images/foo.jpg'
        end

      path = File.join(File.dirname(__FILE__), 'data/han-solo.jpg') 
      assert{ test(?s, path) }
      up = Upload.new(path)
      comment = Comment.new

      c = conducer_class.new( comment, :up => {:file => Upload.new(path)} ) 

      upload = assert{ c.get(:up) }
      assert{ upload.is_a?(Dao::Upload) }

      assert{ test(?f, upload.path) }
      assert{ File.basename(upload.path) == File.basename(path) }
      assert{ IO.read(upload.path) == IO.read(path) }

      assert{ c.save }

      value_was_relayed = assert{ comment.attributes[:up] == upload._value }
      value_was_cleared = assert{ !test(?f, upload.path) }

      assert{ test(?s, path) }
ensure
$pry=false
end
    end
  end

##
#
  context :collections do
    test 'can be created from page-y blessed arrays' do
      paginated = Paginated[Post.new, Post.new, Post.new]
      paginated.limit = 42
      paginated.offset = 42.0
      paginated.total_count = 420

      conducer_class = new_conducer_class

      conducer_class.collection_for(paginated)
      collection = assert{ conducer_class.collection_for(paginated) }
      assert{ collection.models == paginated }
      assert{ collection.limit == 42 }
      assert{ collection.offset == 42.0 }
      assert{ collection.total_count == 420 }

      user = User.new
      collection = assert{ conducer_class.collection_for(paginated){|model| conducer_class.for(:show, user, model)} }
      assert{ collection.all?{|conducer| conducer.action == :show} }
      assert{ collection.all?{|conducer| conducer.models.first==user} }
      assert{ collection.all?{|conducer| conducer.models.last.is_a?(Post)} }
    end
  end

##
#
  context :callbacks do
    test 'can be added lazily in an ad-hoc fashion' do
      callbacks = []

      conducer_class =
        new_conducer_class do
          before_initialize do
            callbacks.push(:before_initialize)
          end

          after_initialize do
            callbacks.push(:after_initialize)
          end

          define_method(:foobar){ 42 }

          before :foobar do
            callbacks.push(:before_foobar)
          end

          after :foobar do
            callbacks.push(:after_foobar)
          end
        end

      c = assert{ conducer_class.new }
      assert{ callbacks == [:before_initialize, :after_initialize] }
      assert{ c.foobar; true }
      assert{ callbacks == [:before_initialize, :after_initialize, :before_foobar, :after_foobar] }
    end
  end

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

  def setup
    $db = Dao::Db.new(:path => 'test/db.yml')
    Dao::Db.instance = $db
    collection = $db['foos']
    %w( a b c ).each do |name|
      collection.save(
        :name => name, :created_at => Time.now.to_f, :a => %w( x y z ), :h => {:k => :v}
      )
    end
  end

  def teardown
    $db = Dao::Db.new(:path => 'test/db.yml')
    $db.rm_f
  end

  def db
    $db
  end

  def collection
    $db[:foos]
  end

  class Mounted
    def Mounted.mount(*args, &block)
      new(*args, &block)
    end

    def _set
    end

    def _key
    end

    def _value
    end

    def _clear
    end
  end

  class Upload < StringIO
    attr_accessor :path

    def initialize(path)
      super(IO.read(@path = path))
    end

    def dup
      self.class.new(path)
    end
  end

  class Model
    class << self
      def model_name
        name = self.name.split(/::/).last
        ActiveModel::Name.new(Map[:name, name])
      end
    end

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
      "#{ self.class.name }(#{ attributes.inspect.strip })"
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

  class Paginated < ::Array
    attr_accessor :limit
    attr_accessor :offset
    attr_accessor :total_count
  end

  class User < Model
  end

  class Post < Model
  end

  class Comment < Model
  end
end
