module Dao
  class Result < ::Map
    def initialize(*args, &block)
      options = Dao.options_for!(args)

      self.path = args.shift || options[:path] || Path.default
      self.route = options[:route] || Route.default
      self.mode = options[:mode] || Mode.default
      self.status = options[:status] || Status.default
      self.params = options[:params] || Params.new
      self.errors = options[:errors] || Errors.new
      self.data = options[:data] || Data.new
    end

    def inspect
      ::JSON.pretty_generate(self, :max_nesting => 0)
    end
  end
end
