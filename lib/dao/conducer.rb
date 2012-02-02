# -*- encoding : utf-8 -*-
module Dao
##
#
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
    #include ActiveModel::Conversion

    #extend ActiveModel::Translation
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

##
#
    include Wrap

    %w[
      initialize save create update destroy run_validations
    ].each do |method|
      wrap(method)
    end

    wrap_alias(:validation, :run_validations)

    before :initialize do |*args|
      init(*args)
    end

    after :initialize do |*args|
      identify!
      initialize_for_current_action!
    end

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
    %w(
      name
      params
      attributes
      errors
      form
      models
    ).each{|a| fattr(a)}

    alias_method(:data, :attributes)

    def init(*args, &block)
      controllers, args = args.partition{|arg| arg.is_a?(ActionController::Base)}
      hashes, args = args.partition{|arg| arg.is_a?(Hash)}
      models, args = args.partition{|arg| arg.respond_to?(:save) or arg.respond_to?(:new_record?)}

      @name = self.class.model_name.singular.sub(/_+$/, '')
      @attributes = Attributes.for(self)
      @form = Form.for(self)
      @params = Map.new

      validator.reset

      @errors = validator.errors
      @status = validator.status

      set_controller(controllers.shift || Dao.current_controller || Dao.mock_controller)

      @models = models.flatten.compact

      update_attributes(update_params(*hashes))

      self
    end

    def initialize(*args, &block)
    end

    def identify!(*args, &block)
      id = identifier
      attributes[:id] ||= id
      attributes[:_id] ||= id
      id
    end

    def initialize_for_current_action!
      current_action = ::Current.controller.send(:action_name).to_s

      method = "initialize_for_#{ current_action }"
      return(send(method)) if respond_to?(method)

      synonyms = {
        'new' => 'create',
        'edit' => 'update'
      }

      synonym = synonyms[current_action] || synonyms.invert[current_action]
      method = "initialize_for_#{ synonym }"
      return(send(method)) if synonym and respond_to?(method)

      nil
    end

    def models(*patterns)
      if patterns.empty?
        @models
      else
        @models.detect{|model| patterns.all?{|pattern| pattern === model}}
      end
    end

    def identifier
      model = @models.last
      model and !model.new_record? and model.id
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

    def errors
      validator.errors
    end

    def status
      validator.status
    end

## instance_methods
#
    def inspect
      Dao.json_for(@attributes)
    end

    def id
      @attributes[:id] || @attributes[:_id]
    end

    def id?
      id
    end

    def id=(id)
      @attributes[:id] = id
    end

    def key_for(*keys)
      keys.flatten.map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
      #key = keys.flatten.join('.').strip
      #key.split(%r/\s*[,.]\s*/).map{|key| key =~ %r/^\d+$/ ? Integer(key) : key}
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

    def inspect
      "#{ self.class.name }(#{ @attributes.inspect.chomp })"
    end

# active_model support
#


## include ActiveModel::Conversion
#
    def to_model
      self
    end

    def to_key
      id ? [id] : nil
    end

    def to_param
      persisted? ? to_key.join('-') : nil
    end

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


## extend ActiveModel::Translation
#
    def self.human_attribute_name(attribute, options = {})
      attribute
    end

    def self.lookup_ancestors
      [self]
    end

    def read_attribute_for_validation(key)
      self[key]
    end

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

    def update_attributes(attributes = {})
      @attributes.set(attributes)
      @attributes
    end

    def update_attributes!(*args, &block)
      update_attributes(*args, &block)
    ensure
      save!
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
