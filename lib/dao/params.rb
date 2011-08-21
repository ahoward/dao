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
    attr_accessor :result
    attr_accessor :route
    attr_accessor :path
    attr_accessor :status

    attr_accessor :errors
    attr_accessor :form

    include Validations

    def initialize(*args, &block)
      @path = Path.default
      @status = Status.default

      @errors = Errors.for(self)
      @validator = Validator.for(self)
      @form = Form.for(self)
      super
    end

    def attributes
      self
    end

    def name
      path
    end

  # look good for inspect
  #
    def inspect
      ::JSON.pretty_generate(self, :max_nesting => 0)
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
