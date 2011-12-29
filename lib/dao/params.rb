# -*- encoding : utf-8 -*-
module Dao
  class Params < ::Map
  # mixins
  #
    include Validations

  # class methods
  #
    class << Params
    end

  # instance methods
  #
    attr_accessor :path
    attr_accessor :route
    attr_accessor :form

    def initialize(*args, &block)
      options = Dao.options_for!(args)

      @path = args.shift || options[:path] || Path.default
      @route = options[:route] || Route.default
      @form = options[:form] || Form.for(self)

      update(options[:params]) if options[:params]

      super
    end

    def attributes
      self
    end

    fattr(:name){ path }

  # look good for inspect
  #
    def inspect
      Dao.json_for(self)
    end

  # support updates with dao-ish objects
  #
    add_conversion_method!(:to_dao)
    add_conversion_method!(:as_dao)

    def update(*args, &block)
      if args.size==1 and args.first.respond_to?(:to_dao)
        to_dao = args.first.to_dao
        return super(to_dao)
      end
      super
    end
  end
end
