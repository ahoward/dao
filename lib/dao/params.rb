module Dao
  class Params < ::Map
  # mixins
  #
    include Validations::Mixin

  # class methods
  #
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

  # instance methods
  #
    attr_accessor :result
    attr_accessor :path
    attr_accessor :status
    attr_accessor :errors
    attr_accessor :validations
    attr_accessor :form

    def initialize(*args, &block)
      @path = Path.default
      @status = Status.default
      @errors = Errors.new
      @validations = Validations.for(self)
      @form = Form.for(self)
      super
    end

    def inspect
      ::JSON.pretty_generate(self, :max_nesting => 0)
    end
  end
end
