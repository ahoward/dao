module Dao
  class Result < ::Map
    def initialize(*args, &block)
      options = Dao.options_for!(args)

      self.path = args.shift || options[:path] || Path.default
      self.mode = options[:mode] || Mode.default
      self.status = options[:status] || Status.default
      self.errors = options[:errors] || Errors.new
      self.params = options[:params] || Params.new
      self.data = options[:data] || Data.new

      params.result = self
      params.path = self.path
      params.status = self.status
      params.errors = self.errors
    end

    def error!
      raise Dao::Error::Result.for(self)
    end

    def inspect
      ::JSON.pretty_generate(self, :max_nesting => 0)
    end
  end
end
