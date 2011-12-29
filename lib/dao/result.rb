# -*- encoding : utf-8 -*-
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

=begin
    %w(
      path
      route
      mode
      status
      params
      errors
      data
    ).each do |attr|

      module_eval <<-__, __FILE__, __LINE__
        def #{ attr }(*value)
          unless value.empty?
            self["#{ attr }"] = value.first
          end
          self["#{ attr }"]
        end

        def #{ attr }=(value)
          self["#{ attr }"] = value
        end
      __

    end

    def name
      path
    end

    def attributes
      params
    end
=end


    def form
      @form ||= (
        Form.new.tap do |f|
          f.object = self
          f.attributes = params
          f.errors = errors
          f.status = status
          f.name = path
        end
      )
    end

    def inspect
      Dao.json_for(self)
    end
  end
end
