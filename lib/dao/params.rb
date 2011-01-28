module Dao
  class Params < ::Map
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
    attr_accessor :endpoint
    attr_accessor :params
    attr_accessor :result

    def Params.for(*args, &block)
      options = Dao.options_for!(args)

      api = options[:api]
      endpoint = options[:endpoint]
      updates = options[:params]

      params = new()
      params.api = api
      params.endpoint = endpoint

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

    unless Object.new.respond_to?(:instance_exec)
      module InstanceExecHelper; end
      include InstanceExecHelper

      def instance_exec(*args, &block)
        begin
          old_critical, Thread.critical = Thread.critical, true
          n = 0
          n += 1 while respond_to?(mname="__instance_exec_#{ n }__")
          InstanceExecHelper.module_eval{ define_method(mname, &block) }
        ensure
          Thread.critical = old_critical
        end
        begin
          ret = send(mname, *args)
        ensure
          InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
        end
        ret
      end
    end
  end


  def Dao.parse(*args, &block)
    Params.parse(*args, &block)
  end
end
