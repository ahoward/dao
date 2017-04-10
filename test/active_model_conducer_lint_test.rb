# -*- encoding : utf-8 -*-
class LintTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  class LintConducer < Dao::Conducer; end
        
  def setup
    @model = LintConducer.new
  end
end


BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')

  require File.join(libdir, 'dao')
  require File.join(testdir, 'testing')
}
