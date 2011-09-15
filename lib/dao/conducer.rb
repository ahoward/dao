module Dao

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

    extend ActiveModel::Callbacks

    define_model_callbacks(:save, :create, :update, :destroy)
    define_model_callbacks(:reset, :initialize, :find, :touch)
    include ActiveModel::Validations::Callbacks

##
#
    include Dao::Validations
    include Dao::Current

## class_methods
#
    class << Conducer
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
        model_name_for(name.to_s.sub(/Conducer$/, ''))
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
      attributes
      errors
      form
    ).each{|a| fattr(a)}

    def self.new(*args, &block)
      allocate.tap do |conducer|
        conducer.running_callbacks(:reset, :initialize) do
          conducer.send(:reset, *args, &block)
          conducer.send(:initialize, *args, &block)
        end
      end
    end

    def running_callbacks(*args, &block)
      which = args.shift
      if args.empty?
        run_callbacks(which, &block)
      else
        run_callbacks(which){ running_callbacks(*args, &block) }
      end
    end

    def reset(*args, &block)
      controllers, args = args.partition{|arg| arg.is_a?(ActionController::Base)}
      hashes, args = args.partition{|arg| arg.is_a?(Hash)}

      @name = self.class.model_name.singular
      @attributes = Attributes.for(self)
      @form = Form.for(self)

      validator.reset

      set_controller(controllers.shift || Dao.current_controller || Dao.mock_controller)

      hashes.each do |hash|
        hash.each do |key, val|
          @attributes.set(key_for(key) => val)
        end
      end

      self
    end

    def errors
      validator.errors
    end

    def status
      validator.status
    end

    def initialize(*args, &block)
    end

## instance_methods
#
    def inspect
      ::JSON.pretty_generate(@attributes, :max_nesting => 0)
    end

    def id
      @attributes[:id] || @attributes[:_id]
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
    url_helpers = Rails.application.try(:routes).try(:url_helpers)
    include(url_helpers) if url_helpers
    include(ActionView::Helpers) if defined?(ActionView::Helpers)

    def controller
      @controller ||= (Dao.current_controller || Dao.mock_controller)
      @controller
    end

    def controller=(controller)
      @controller = controller
    ensure
      default_url_options[:protocol] = @controller.request.protocol
      default_url_options[:host] = @controller.request.host
      default_url_options[:port] = @controller.request.port
    end

    def set_controller(controller)
      self.controller = controller
    end

    controller_delegates = %w(
      render
      render_to_string
    )

    controller_delegates.each do |method|
      module_eval <<-__, __FILE__, __LINE__
        def #{ method }(*args, &block)
          controller.#{ method }(*args, &block)
        end
      __
    end

## generic crud support assuming valid .all, .find, #save and #destroy
#
=begin
    def self.create(*args, &block)
      allocate.tap do |conducer|
        conducer.running_callbacks :reset, :initialize, :create do
          conducer.send(:reset, *args, &block)
          conducer.send(:initialize, *args, &block)
          return false unless conducer.save
        end
      end
    end

    def self.create!(*args, &block)
      allocate.tap do |conducer|
        conducer.running_callbacks :reset, :initialize, :create do
          conducer.send(:reset, *args, &block)
          conducer.send(:initialize, *args, &block)
          raise!(:validation_error) unless conducer.save
        end
      end
    end

    def self.blank(params = {})
      new
    end

    def self.build(params = {})
      new
    end

    def self.show(id)
      find(id)
    end

    def self.index(params = {})
      all(params)
    end

    def self.edit(id)
      find(id)
    end

    def self.update(id)
      find(id)
    end

    def self.destroy(id)
      find(id)
    end
=end

    def reload
      attributes =
        if id
          conducer = self.class.find(id)
          conducer ? conducer.attributes : {}
        else
          {}
        end
      reset(attributes)
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

  Dao.load('conducer/attributes.rb')
  Dao.load('conducer/crud.rb')
end
