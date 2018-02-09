# -*- encoding : utf-8 -*-
module Dao
##
#
  Dao.load('conducer/attributes.rb')
  Dao.load('conducer/collection.rb')
  Dao.load('conducer/active_model.rb')
  Dao.load('conducer/controller_support.rb')
  Dao.load('conducer/callback_support.rb')
  Dao.load('conducer/view_support.rb')

##
#
  class Conducer
  ##
  #
    include Dao::Validations

  ## class_methods
  #
    class << Conducer
      def inherited(other)
        super
      ensure
        other.build_collection_class!
        subclasses.push(other)
        subclasses.uniq!
      end

      def subclasses
        defined?(@@subclasses) ? @@subclasses : (@@subclasses = [])
      end

      def name(*args)
        return send('name=', args.first) unless args.empty?
        @name ||= super
      end

      def name=(name)
        @name = name.to_s
      end

      def controller
        Dao.current_controller || Dao.mock_controller
      end

      def controller=(controller)
        Dao.current_controller = controller
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

      def conduces?(model)
        model_class = model.is_a?(Class) ? model : model.class
        model_class.model_name == (self.conduces || self).model_name
      end

      def conduces(*args)
        unless args.blank?
          @conduces = args.shift
          raise(ArgumentError, @conduces.inspect) unless @conduces.respond_to?(:model_name)
        end
        @conduces ||= nil
      end

      def conduces=(model)
        conduces(model)
      end
    end

  # instance methods
  #
    %w[
      attributes
      form
      params
      errors
      messages
      models
      model
      conduces
    ].each{|attr| fattr(attr)}

  # ctors
  #
    def Conducer.new(*args, &block)
      allocate.tap do |conducer|
        args = Dao.call(conducer, :process_arguments, *args)

        Dao.call(conducer, :before_initialize, *args, &block)
        Dao.call(conducer, :initialize, *args, &block)
        Dao.call(conducer, :after_initialize, *args, &block)
      end
    end

    def Conducer.for(*args, &block)
      action =
        case args.first
          when Action, Symbol, String
            args.shift.to_s
          else
            controller.send(:action_name).to_s
        end

      new(Action.new(action), *args, &block)
    end

    def Conducer.call(*args, &block)
      self.for(*args, &block)
    end

    %w( new create edit update destroy ).each do |action|
      class_eval <<-__, __FILE__, __LINE__
        def Conducer.for_#{ action }(*args, &block)
          Conducer.for(#{ action.inspect }, *args, &block)
        end
      __
    end

    def process_arguments(*args)
      controllers, args = args.partition{|arg| arg.is_a?(ActionController::Base)}
      actions, args = args.partition{|arg| arg.is_a?(Action)}

      controller = controllers.shift || Dao.current_controller || Dao.mock_controller
      action = actions.shift

      set_controller(controller) if controller
      set_action(action) if action

      args.map{|arg| arg.class == Hash ? Map.for(arg) : arg}
    end

    def before_initialize(*args, &block)
      models, args = args.partition{|arg| arg.respond_to?(:persisted?) }
      params, args = args.partition{|arg| arg.is_a?(Hash)}

      @params = Map.new
      @attributes = Attributes.for(self)
      @messages = Messages.for(self)

      @form = Form.for(self)
      @form.name = self.class.model_name.singular.sub(/_+$/, '')

      @errors = validator.errors

      set_models(models)

      set_mounts(self.class.mounted)

      update_params(*params) unless params.empty?

      @initialize_overridden = true
    end

    def initialize(*args, &block)
      @initialize_overridden = false
      update_models(models) unless models.empty?
    end

    def after_initialize(*args, &block)
      unless @initialize_overridden
        initialize_for_action(*args, &block)
        update_attributes(params) unless params.empty?
      end
    end

    def initialize_for_action(*args, &block)
      @action.call(:initialize, *args, &block)
    end

  #
    def set_models(*models)
      @models =
        models.flatten.compact

      candidates =
        @models.select{|model| conduces?(model)}

      @model =
        case
          when candidates.size == 1
            candidates.first
          else
            @models.first
        end

      @models.each do |model|
        key = model_key_for(model)
        ivar = "@#{ key }"
        instance_variable_set(ivar, model) unless instance_variable_defined?(ivar)
      end
    end

    def update_models(*models)
      models.flatten.compact.each do |model|
        if conduces?(model)
          update_attributes(model.attributes)
        else
          update_attributes(model_key_for(model), model.attributes)
        end
      end
    end

    def model_key_for(model)
      case model
        when String
          model
        else
          model.class.name
      end.demodulize.underscore
    end

  #
    def conduces(*args)
      if args.empty?
        @model
      else
        @model = args.flatten.compact.first
        @models.delete(@model)
        @models.unshift(@model)
        @model
      end
    end
    alias_method(:set_model, :conduces)

    def conduces=(model)
      conduces(model)
    end

    def conduces?(model)
      if defined?(@model)
        @model == model
      else
        self.class.conduces?(model)
      end
    end

  #
    def set_mounts(list)
      list.each do |args, block|
        mount(*args, &block)
      end
    end

    def mount(object, *args, &block)
      mounted = object.mount(self, *args, &block)
    ensure
      if mounted
        Dao.ensure_interface!(mounted, :_set, :_key, :_value, :_clear)
        self.mounted.push(mounted)
      end
    end

    def mounted
      @mounted ||= []
    end

    def self.mount(*args, &block)
      mounted.push([args, block])
    end

    def self.mounted
      @mounted ||= []
    end

  #
    def update_attributes(*args, &block)
      attributes =
        case
          when args.size == 1 && args.first.is_a?(Hash)
            args.first
          else
            if args.size >= 2
              val = args.pop
              key = args.flatten.compact
              {key => val}
            else
              {}
            end
        end

      @attributes.add(attributes)

      update_mounted_attributes!

      @attributes
    end

    def update_mounted_attributes!
      deepest_mounts_first = mounted.sort_by{|mnt| mnt._key.size}.reverse

      deepest_mounts_first.each do |mount|
        value = @attributes.get(mount._key)
        next if(value.nil? or value.object_id == mount.object_id)
        mount._set(value) if mount.respond_to?(:_set)
        @attributes.set(mount._key => mount)
      end
    end

    def update_attributes!(*args, &block)
      update_attributes(*args, &block)
    ensure
      save!
    end

    def attributes=(attributes)
      @attributes.clear
      update_attributes(attributes)
    end

    def set(*args, &block)
      update_attributes(*args, &block)
    end

    def has?(*key)
      key = key_for(key)
      @attributes.has?(key)
    end

    def get(*key)
      key = key_for(key)
      @attributes.get(key)
    end

    def [](key)
      get(key)
    end

    def []=(key, val)
      set(key, val)
    end

    def method_missing(method, *args, &block)
      re = /^([^=!?]+)([=!?])?$/imox

      _, key, suffix = re.match(method.to_s).to_a

      case suffix
        when '='
          set(key, args.first)
        when '!'
          set(key, args.size > 0 ? args.first : true)
        when '?'
          has?(key)
        else
          case key
            when /^current_(.*)/
              Current.send($1)
            else
              has?(key) ? get(key) : super
          end
      end
    end

  #
    def update_params(*hashes)
      hashes.flatten.compact.each do |hash|
        @params.add(hash)
      end
    end

  # id support 
  #
    def id(*args)
      if args.blank?
        @attributes[:_id] || @attributes[:id]
      else
        id = args.flatten.compact.shift
        key = [:_id, :id].detect{|k| @attributes.has_key?(k)} || :id
        @attributes[key] = id_for(id)
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

    def id_for(object)
      model?(object) ? object.id : object
    end

    def model?(object)
      object.respond_to?(:persisted?)
    end

  # mixin controller support
  #
    class_eval(&ControllerSupport)

  # mixin callback support
  #
    class_eval(&CallbackSupport)

  # mixin view support
  #
    class_eval(&ViewSupport)

  # persistence
  #
    def save
      default_save
    end

    def default_save
      return false unless valid?

      if @model
        attributes = self.attributes.dup

        @models.each do |model|
          next if model == @model
          key = model_key_for(model)
          attributes.delete(key)
        end

        mounted.each do |mnt|
          attributes.set(mnt._key, mnt._value)
        end

        @model.update_attributes(attributes)

        if @model.save
          mounted.each{|mnt| mnt._clear}
          return true
        else
          errors.relay(@model.errors)
          return false
        end
      else
        raise NotImplementedError
      end
    end
    
    def save!
      raise!(:validation_error, errors) unless !!save
      true
    end

    def destroy
      if @model and @model.destroy
        return true
      else
        raise NotImplementedError
      end
    end

    def destroy!
      raise!(:deletion_error) unless !!destroy
      true
    end

  # misc
  #
    def key_for(key)
      Dao.key_for(key)
    end

    def errors
      validator.errors
    end

    def model_name
      self.class.model_name
    end

    def form
      @form
    end

    def form_builder
      Form::Builder
    end

    def helper
      @helper ||= ::Helper.new
    end

    def h(*args)
      CGI.escapeHTML(args.join(' '))
    end

    def raise!(*args, &block)
      self.class.raise!(*args, &block)
    end

    def as_json(*args, &block)
      @attributes
    end

    def conducer
      self
    end

    def inspect
      "#{ self.class.name }(#{ @attributes.inspect.strip })"
    end

    def to_s
      inspect
    end
  end

  Resource = Conducer
  Presenter = Conducer
  Conductor = Conducer
  Model = Conducer
end
