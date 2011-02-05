module Dao
  class Context
    Attrs = %w( api interface params result method args )
    Attrs.each{|attr| attr_accessor(attr)}

    def initialize(*args, &block)
      options = Dao.options_for!(args)

      api = options[:api]
      interface = options[:interface]
      params = options[:params]
    
      params = Params.for(:api => api, :interface => interface, :params => params)
      result = Result.new(:api => api, :interface => interface, :params => params)
      params.result = result

      method = interface.method.bind(api)
      args = [params, result].slice(0, method.arity)

      self.api = api
      self.interface = interface
      self.params = params
      self.result = result
      self.method = method
      self.args = args
    end

    def call()
      method.call(*args)
    end

    def update(options = {})
      options.each do |key, val|
        send("#{ key }=", val)
      end
    end
  end
end
