module Dao
  class Params < ::Map
  # mixins
  #
    include Validations

  # class methods
  #
    class << Params
      def normalize_parameters(params)
        dao = (params.delete('dao') || {}).merge(params.delete(:dao) || {})

        unless dao.blank?
          dao.each do |key, paths_and_values|
            params[key] = nil
            next if paths_and_values.blank?

            map = Map.new

            paths_and_values.each do |path, value|
              keys = keys_for(path)
              map.set(keys => value)
            end

            params[key] = map
          end
        end

        params[:dao] = true
        params
      end

      def parse(prefix, params = {}, options = {})
      # setup
      #
        prefix = prefix.to_s
        params = Map.new(params || {})
        parsed = Params.new
        base = Map.new(params || {})
        options = Map.options(options || {})
        parsed.update(params[prefix]) if params.has_key?(prefix)

        form_encoded = params.get(:dao, prefix)

        if form_encoded

          base.delete(:dao)
          form_encoded.each do |key, value|
            next unless(key.is_a?(String) or key.is_a?(Symbol))
            key = key.to_s
            keys = keys_for(key)
            parsed.set(keys => value)
            base.delete(key)
          end

        else
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
      # fall through iff params have already been normalized (by a
      # before_filter)
      #
        return params if params[:dao] == true

      # fall through on already parsed params
      #
        return params if params.is_a?(Params)

      # build a smarter object
      #
        params = Params.new(params)

      # be prepared to handle form encoded params
      #
        #return Params.parse(path, params[:dao][path], options) if
          #params.has?(:dao, path)

      # now we go a-looking for dao-y parameter encoding
      #
        parsed = Params.parse(path, params, options)
        return parsed unless parsed.empty?

      # otherwise - just return 'em
      #
        return params
      end
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
