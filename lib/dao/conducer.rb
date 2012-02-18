# -*- encoding : utf-8 -*-
module Dao
##
#
  Dao.load('conducer/controller_support.rb')
  Dao.load('conducer/view_support.rb')
  Dao.load('conducer/attributes.rb')
  Dao.load('conducer/collection.rb')
  Dao.load('conducer/autocrud.rb')

##
#
  class Conducer
##
#      
    include ActiveModel::Naming
    include ActiveModel::Conversion
    extend ActiveModel::Translation

    #include ActiveModel::AttributeMethods
    #include ActiveModel::Serialization
    #include ActiveModel::Dirty
    #include ActiveModel::MassAssignmentSecurity
    #include ActiveModel::Observing
    #include ActiveModel::Serializers::JSON
    #include ActiveModel::Serializers::Xml
     
    #include ActiveModel::Validations

    #extend ActiveModel::Callbacks
    #define_model_callbacks(:save, :create, :update, :destroy)
    #define_model_callbacks(:reset, :initialize, :find, :touch)
    #include ActiveModel::Validations::Callbacks

##
#
    include Dao::Validations
    include Dao::Current

## callbacks
#
    include Wrap

    %w[
      initialize
      save
      create
      update
      destroy
      update_attributes
      run_validations
    ].each do |method|

      wrap(method)

      module_eval <<-__, __FILE__, __LINE__
        def before_#{ method }(*args, &block) end
        def after_#{ method }(*args, &block) end
      __

      before(method){|*args| Dao.call(self, "before_#{ method }", *args) }
      after(method){|*args| Dao.call(self, "after_#{ method }", *args) }
    end

    wrap_alias(:validation, :run_validations)

    before :save do
      halt! unless valid?
      true
    end

    after :save do |saved|
      if saved or id?
        @new_record = false
        @destroyed = false
        @persisted = true
      end
      true
    end

    after :destroy do |destroyed|
      if destroyed or !id?
        @new_record = false
        @destroyed = true
        @persisted = false
      end
      true
    end

## class_methods
#
    class << Conducer
      def new(*args, &block)
        conducer = allocate
        Dao.call(conducer, :initialize!, *args, &block)
        Dao.call(conducer, :initialize, *args, &block)
        conducer
      ensure
        conducer.identify!
      end

      def inherited(other)
        super
      ensure
        other.build_collection_class!
      end

      def build_collection_class!
        begin
          remove_const(:Collection) if const_defined?(:Collection)
        rescue NameError
        end
        collection_class = Class.new(Collection)
        collection_class.conducer_class = self
        const_set(:Collection, collection_class)
      end

      def collection_class
        const_get(:Collection)
      end

      def collection(*args, &block)
        if args.empty? and block.nil?
          const_get(:Collection)
        else
          const_get(:Collection).new(*args, &block)
        end
      end

      def name(*args)
        return send('name=', args.first) unless args.empty?
        @name ||= super
      end

      def name=(name)
        @name = name.to_s
      end

      def model_name(*args)
        return send('model_name=', args.first) unless args.empty?
        @model_name ||= default_model_name
      end

      def model_name=(model_name)
        @model_name = model_name_for(model_name)
      end

      def model_name_for(model_name)
        ActiveModel::Name.new(Map[:name, model_name])
      end

      def default_model_name
        return model_name_for('Conducer') if self == Dao::Conducer
        model_name_for(name.to_s.sub(/Conducer$/, '').sub(/(:|_)+$/, ''))
      end

      def table_name
        @table_name ||= model_name.plural.to_s
      end
      alias_method('collection_name', 'table_name')

      def table_name=(table_name)
        @table_name = table_name.to_s 
      end
      alias_method('collection_name=', 'table_name=')

      def controller
        defined?(@controller) ? @controller : Dao.current_controller
      end

      def controller=(controller)
        @controller = controller
      end

      def mock_controller(*args, &block)
        Dao.mock_controller(*args, &block)
      end

      def current
        @current ||= (defined?(::Current) ? ::Current : Map.new)
      end

      def raise!(*args, &block)
        kind = (args.first.is_a?(Symbol) ? args.shift : 'error').to_s.sub(/_error$/, '')

        case kind
          when /validation/ 
            raise Validations::Error.new(*args, &block)

          when /error/ 
            raise Error.new(*args, &block)

          else
            raise Error.new(*args, &block)
        end
      end
    end

## contructor 
#
    %w[
      name
      params
      attributes
      errors
      form
      models
    ].each{|a| fattr(a)}

    alias_method(:data, :attributes)

    def initialize!(*args, &block)
      controllers, args = args.partition{|arg| arg.is_a?(ActionController::Base)}
      hashes, args = args.partition{|arg| arg.is_a?(Hash)}
      models, args = args.partition{|arg| arg.respond_to?(:save) or arg.respond_to?(:new_record?)}

      @name = self.class.model_name.singular.sub(/_+$/, '')
      @attributes = Attributes.for(self)
      @form = Form.for(self)
      @params = Map.new

      #validator.reset # FIXME - required?

      @errors = validator.errors
      @status = validator.status

      set_controller(controllers.shift || Dao.current_controller || Dao.mock_controller)

      @models = models.flatten.compact

      update_params(*hashes)
    end

    def initialize(*args, &block)
    end

    def update_params(*args, &block)
      hashes, args = args.flatten.compact.partition{|arg| arg.is_a?(Hash)}
      hashes.each{|h| h.each{|k,v| @params.set(key_for(k) => v)}}
      @params
    end

    def update_attributes(attributes = {})
      @attributes.set(attributes)
      @attributes
    end

    def update_attributes!(*args, &block)
      update_attributes(*args, &block)
    ensure
      save!
    end

    def identify!(*args, &block)
      return if !id.blank?

      unless((id = identifier).blank?)
        self.id = id
      end
    end

    def identifier
      model = @models.last
      model.id if(model and model.persisted?)
    end

    def models(*patterns)
      if patterns.empty?
        @models
      else
        @models.detect{|model| patterns.all?{|pattern| pattern === model}}
      end
    end

    def model
      @models.last
    end

    def model=(model)
      @models.push(@models.delete(model)).compact.uniq
    end

    def errors
      validator.errors
    end

    def status
      validator.status
    end

  ## crud action based lifecycles
  #
    %w( new create edit update destroy ).each do |action|
      module_eval <<-__, __FILE__, __LINE__
        def Conducer.for_#{ action }(*args, &block)
          conducer = new(*args, &block)
          conducer.action = Action.new('#{ action }', conducer)
          conducer.action.call(:initialize, *args, &block)
          conducer.update_attributes(conducer.params)
          conducer.action.call(:update_attributes, *args, &block)
          conducer
        end
      __
    end

  ## upload_cache support
  #
    def upload_caches!(*args)
      options = args.extract_options!.to_options!
      keys = args.flatten.compact

      upload_cache = UploadCache.cache(attributes, keys, options)
      upload_cache.name = Form.name_for(name, upload_cache.cache_key)
      upload_caches[keys] = upload_cache
      upload_cache
    end
    alias_method('upload_cache!', 'upload_caches!')

    def upload_caches(*args)
      @upload_caches ||= Map.new
      if args.blank?
        @upload_caches
      else
        keys = args.flatten.compact
        @upload_caches[keys]
      end
    end
    alias_method('upload_cache', 'upload_caches')

  ## instance_methods
  #
    def id(*args)
      if args.blank?
        @attributes[:id] || @attributes[:_id]
      else
        id = args.flatten.compact.shift
        @attributes[:id] = id
      end
    end

    def id?
      self.id
    end

    def id=(id)
      self.id(id)
    end

    def id!(id)
      self.id(id)
    end

    def [](key)
      @attributes.get(key_for(key))
    end

    def []=(key, val)
      @attributes.set(key_for(key), val)
    end

    %w( set get has? update ).each do |m|
      module_eval <<-__, __FILE__, __LINE__
        def #{ m }(*a, &b)
          @attributes.#{ m }(*a, &b)
        end
      __
    end

    def method_missing(method, *args, &block)
      case method.to_s
        when /^(.*)[=]$/
          key = key_for($1)
          val = args.first
          @attributes.set(key => val)

        when /^(.*)[!]$/
          key = key_for($1)
          val = true
          @attributes.set(key => val)

        when /^(.*)[?]$/
          key = key_for($1)
          @attributes.has?(key)

        else
          key = key_for(method)
          return @attributes.get(key) if @attributes.has?(key)
          super
      end
    end

    def key_for(*keys)
      keys.flatten.map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
    end

    def inspect
      "#{ self.class.name }(#{ @attributes.inspect.chomp })"
    end

  ## active_model support
  #
    def persisted
      !!(defined?(@persisted) ? @persisted : id)
    end
    def persisted?
      persisted
    end
    def persisted=(value)
      @persisted = !!value
    end
    def persisted!
      self.persisted = true
    end

    def new_record
      !!(defined?(@new_record) ? @new_record : id.blank?)
    end
    def new_record?
      new_record
    end
    def new_record=(value)
      @new_record = !!value
    end
    def new_record!
      self.new_record = true
    end

    def destroyed
      !!(defined?(@destroyed) ? @destroyed : id.blank?)
    end
    def destroyed?
      destroyed
    end
    def destroyed=(value)
      @destroyed = !!value
    end
    def destroyed!
      self.destroyed = true
    end

    def read_attribute_for_validation(key)
      self[key]
    end

  ## controller support
  #
    module_eval(&ControllerSupport)

  ## view support
  #
    module_eval(&ViewSupport)

  ##
  #
    def save
      NotImplementedError
    end

    def destroy
      NotImplementedError
    end

  ##
  #
    def reload
      attributes.replace(
        if id
          conducer = self.class.find(id)
          conducer ? conducer.attributes : {}
        else
          {}
        end
      )
      self
    end

    def save!
      saved = !!save
      raise!(:validation_error) unless saved
      true
    end

  ## misc
  #
    def model_name
      self.class.model_name
    end

    def form
      @form
    end

    def raise!(*args, &block)
      self.class.raise!(*args, &block)
    end

    def as_json
      @attributes
    end

    def conducer
      self
    end
  end
end
