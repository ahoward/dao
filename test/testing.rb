require 'test/unit'

testdir = File.expand_path(File.dirname(__FILE__))
rootdir = File.dirname(testdir)
libdir = File.join(rootdir, 'lib')

STDOUT.sync = true

$:.unshift(testdir) unless $:.include?(testdir)
$:.unshift(libdir) unless $:.include?(libdir)
$:.unshift(rootdir) unless $:.include?(rootdir)

def Testing(*args, &block)
  Class.new(Test::Unit::TestCase) do

    def self.slug_for(*args)
      string = args.flatten.compact.join('-')
      words = string.to_s.scan(%r/\w+/)
      words.map!{|word| word.gsub %r/[^0-9a-zA-Z_-]/, ''}
      words.delete_if{|word| word.nil? or word.strip.empty?}
      words.join('-').downcase
    end

    def self.testing_subclass_count
      @@testing_subclass_count = '0' unless defined?(@@testing_subclass_count) 
      @@testing_subclass_count
    end

    self.testing_subclass_count.succ!
    slug = slug_for(*args).gsub(%r/-/,'_')
    name = ['TESTING', '%03d' % self.testing_subclass_count, slug].delete_if{|part| part.empty?}.join('_')
    name = name.upcase!
    const_set(:Name, name)
    def self.name() const_get(:Name) end

    def self.testno()
      '%05d' % (@testno ||= 0)
    ensure
      @testno += 1
    end

    def self.testing(*args, &block)
      method = ["test", testno, slug_for(*args)].delete_if{|part| part.empty?}.join('_')
      define_method("test_#{ testno }_#{ slug_for(*args) }", &block)
    end

    alias_method '__assert__', 'assert'

    def assert(*args, &block)
      if block
        label = "assert(#{ args.join(' ') })"
        result = nil
        assert_nothing_raised{ result = block.call }
        __assert__(result, label)
        result
      else
        result = args.shift
        label = "assert(#{ args.join(' ') })"
        __assert__(result, label)
        result
      end
    end

    def subclass_of exception
      class << exception
        def ==(other) super or self > other end
      end
      exception
    end

    module_eval &block
    self
  end
end
