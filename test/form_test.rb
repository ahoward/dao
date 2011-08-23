Testing Dao::Form do
  testing '.new' do
    form = new_form() 
    form = new_named_form() 
  end

  testing 'name_for' do
    assert{ Dao::Form.name_for(:foo, :a, :b) == 'dao[foo][a.b]' }
    assert{ new_form.name_for(:a, :b) == 'dao[form][a.b]' }
    assert{ new_named_form.name_for(:a, :b) == 'dao[name][a.b]' }
    assert{ new_named_form(:foo).name_for(:a, :b) == 'dao[foo][a.b]' }
  end

protected
  def new_form
    assert{ Dao::Form.new }
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



BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')

  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
  require File.join(testdir, 'helper')
}
