module Dao
  class Params < ::Map
    include Dao::InstanceExec

    class << Params
      def parse(prefix, params = {}, options = {})
        prefix = prefix.to_s
        params = Map.new(params || {})
        base = Map.new(params || {})
        options = Map.options(options || {})
        parsed = Params.new
        parsed.update(params[prefix]) if params.has_key?(prefix)

        re = %r/^ #{ Regexp.escape(prefix) } (?: [(] ([^)]+) [)] )? $/x

        params.each do |key, value|
          next unless(key.is_a?(String) or key.is_a?(Symbol))
          key = key.to_s
          matched, keys = re.match(key).to_a
          next unless matched
          next unless keys
          keys = keys_for(keys)
          parsed.set(keys => value)
          base.delete(key)
        end

        whitelist = Set.new( [options.getopt([:include, :select, :only])].flatten.compact.map{|k| k.to_s} )
        blacklist = Set.new( [options.getopt([:exclude, :reject, :except])].flatten.compact.map{|k| k.to_s} )

        unless blacklist.empty?
          base.keys.dup.each do |key|
            base.delete(key) if blacklist.include?(key.to_s)
          end
        end

        unless whitelist.empty?
          base.keys.dup.each do |key|
            base.delete(key) unless whitelist.include?(key.to_s)
          end
        end

        if options.getopt(:fold, default=true)
          parsed_and_folded = base.merge(parsed)
        else
          parsed
        end
      end

      def keys_for(keys)
        keys.strip.split(%r/\s*,\s*/).map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
      end

      def process(path, params, options = {})
        return params if params.is_a?(Params)

        parsed = Params.parse(path, params, options)
        return parsed unless parsed.empty?

        return Params.new(params)
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

  def Dao.parse(*args, &block)
    Params.process(*args, &block)
  end
end
