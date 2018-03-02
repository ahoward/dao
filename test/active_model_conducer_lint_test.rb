# -*- encoding : utf-8 -*-
require 'test_helper'
class LintTest < Dao::TestCase
  include ActiveModel::Lint::Tests

  class LintConducer < Dao::Conducer; end

  def setup
    @model = LintConducer.new
  end
end

