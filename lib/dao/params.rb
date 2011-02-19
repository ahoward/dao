module Dao
  class Params < ::Map
    include Dao::InstanceExec

    class << Params
      def parse(prefix, params = {})
        prefix = prefix.to_s
        params = Map.new(params)
        parsed = Params.new
        parsed.update(params[prefix]) if params.has_key?(prefix)

        re = %r/^ #{ Regexp.escape(prefix) } (?: [(] ([^)]+) [)] )? $/x

        params.each do |key, value|
          next unless(key.is_a?(String) or key.is_a?(Symbol))
          key = key.to_s
          matched, keys = re.match(key).to_a
          next unless matched
          next unless keys
          keys = keys.strip.split(%r/\s*,\s*/).map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
          parsed.set(keys => value)
        end

        parsed
      end
    end

    attr_accessor :api
    attr_accessor :interface
    attr_accessor :params
    attr_accessor :result

    def Params.for(*args, &block)
      options = Dao.options_for!(args)

      api = options[:api]
      interface = options[:interface]
      updates = options[:params]

      params = new()
      params.api = api
      params.interface = interface

      params.update(updates) if updates

      params
    end

    def path
      result.path if result
    end

    def status(*args)
      result.status(*args) if result
    end
    def status=(value)
      result.status=value if result
    end

    def errors
      result.errors if result
    end

    def data
      result.data if result
    end

    def validates(*args, &block)
      result.validates(*args, &block) if result
    end

    def validate(*args, &block)
      result.validate(*args, &block) if result
    end

    def valid?
      result.valid? if result
    end

    def validate!
      result.validate! if result
    end
  end

  def Dao.parse(path, params)
    return params if params.is_a?(Params)

    smells_like_unparsed_rails_params = (
      params.has_key?(:action) and
      params.has_key?(:controller) and
      params.class.name =~ /HashWithIndifferentAccess/
    )
    return(Params.parse(path.to_s, params)) if smells_like_unparsed_rails_params

    smells_like_unparsed_params = false
    unparsed_re = %r/^#{ Regexp.escape(path.to_s) }/
    params.each do |key, val|
      if key =~ unparsed_re
        smells_like_unparsed_params = true
        break
      end
    end
    return(Params.parse(path.to_s, params)) if smells_like_unparsed_params

    return Params.new(params) 
  end

=begin
  def Dao.parse(path, params)
    returned = Params.new(params)

    smells_like_rails = (params.has_key?(:action) and params.has_key?(:controller) and params.class.name =~ /HashWithIndifferentAccess/)
    if smells_like_rails
      returned.delete(:action)
      returned.delete(:controller)
      returned.update(Params.parse(path, params))
      return returned
    end

    re = %r/^#{ Regexp.escape(path) }/
    smells_like_unparsed = false
    params.each do |key, val|
      break(smells_like_unparsed = true) if key =~ re
    end
    if smells_like_unparsed
      returned.update(Params.parse(path, params))
      return returned
    end

    return returned
  end
=end
end
