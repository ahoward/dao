# -*- encoding : utf-8 -*-
require 'testing'
class LintTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  class LintConducer < Dao::Conducer; end

  def setup
    @model = LintConducer.new
  end
end

