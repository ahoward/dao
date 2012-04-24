# -*- encoding : utf-8 -*-
module Dao
##
#
  Dao.load('conducer/attributes.rb')
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
        subclasses.push(other)
        subclasses.uniq!
      end

      def subclasses
        defined?(@@subclasses) ? @@subclasses : (@@subclasses = [])
      end

      def collection_for(results, &block)
        block ||= proc{|model| new(model)}
        results.dup.map!(&block)
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
    end

  ## crud-y lifecycle ctors
  #
    def Conducer.for(action, *args, &block)
      allocate.tap do |conducer|
        action = Action.new(action, conducer)
        Dao.call(conducer, :init, action, *args, &block)
        Dao.call(conducer, :initialize, *args, &block)
      end
    end

    def Conducer.call(*args, &block)
      self.for(*args, &block)
    end

    %w( new create edit update destroy ).each do |action|
      module_eval <<-__, __FILE__, __LINE__
        def Conducer.for_#{ action }(*args, &block)
          Conducer.for(#{ action.inspect }, *args, &block)
        end
      __
    end

  ## ctor
  #
    def Conducer.new(*args, &block)
      allocate.tap do |conducer|
        Dao.call(conducer, :init, *args, &block)
        Dao.call(conducer, :initialize, *args, &block)
      end
    end

    %w[
      name
      attributes
      form
      params
      errors
      status
      models
      model
      conduces
    ].each{|attr| fattr(attr)}

  ## init runs *before* initialize - aka inside allocate
  #
    def init(*args, &block)
      controllers, args = args.partition{|arg| arg.is_a?(ActionController::Base)}
      actions, args = args.partition{|arg| arg.is_a?(Action)}
      models, args = args.partition{|arg| arg.respond_to?(:persisted?) }
      hashes, args = args.partition{|arg| arg.is_a?(Hash)}

      @name = self.class.model_name.singular.sub(/_+$/, '')
      @attributes = Attributes.for(self)
      @form = Form.for(self)
      @params = Map.new

      @errors = validator.errors
      @status = validator.status

      set_controller(controllers.shift || Dao.current_controller || Dao.mock_controller)

      set_action(actions.shift) unless actions.empty?

      set_models(models)

      set_mounts(self.class.mounted)

      update_params(hashes)
    end

    def set_models(*models)
      @models =
        models.flatten.compact

      candidates =
        @models.select{|model| model.class.model_name == self.class.model_name}

      @model =
        case candidates.size == 1
          when 1
            candidates.first
          else
            @models.last
        end

      @models.each do |model|
        key = model_key_for(model)
        ivar = "@#{ key }"
        instance_variable_set(ivar, model) unless instance_variable_defined?(ivar)
      end
    end
    alias_method('set_model', 'set_models')

    def update_params(*hashes)
      hashes.flatten.compact.each{|hash| @params.apply(hash)}
    end

  ## a sane initialize is provided for you.  you are free to override it
  # *without* calling super
  #
    def initialize(*args, &block)
      default_initialize(*args, &block)
    end

    def default_initialize(*args, &block)
      initialize_for_action(*args, &block)

      update_attributes(models, params)
    end

    def set_mounts(list)
      list.each do |args, block|
        mount(*args, &block)
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

    def initialize_for_action(*args, &block)
      @action.call(:initialize, *args, &block)
    end

    def conduces(*args)
      if args.empty?
        @model
      else
        @model = args.flatten.compact.first
        @models.delete(@model)
        @models.push(@model)
        @model
      end
    end

    def conduces=(model)
      conduces(model)
    end

    def conduces?(model)
      conduces == model
    end

  ## accessors
  #
    def update_attributes(*args, &block)
    # process updates
    #
      pos = 0

    # process leading models: update_attributes(@user, ...)
    #
      attributes = Map.new

      while(pos < args.size)
        arg = args[pos]
        pos += 1

        if(model?(arg) or (arg.is_a?(Array) and model?(arg.first)))
          models = Array(arg)
          models.each do |model|
            key = conduces?(model) ? nil : model_key_for(model)
            attributes[key] = model
          end
        else
          break
        end
      end

      merge_attributes(attributes)

    # process leading hashes: update_attributes(@user, params, ...)
    #
      attributes = Map.new

      while(pos < args.size)
        arg = args[pos]
        pos += 1

        if arg.is_a?(Hash)
          attributes.update(arg)
        else
          break
        end
      end

      merge_attributes(attributes)

    # process the rest: update_attributes(@user, params, :user, :name, 'Fred')
    #
      args = args[pos -1 .. -1]

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

      merge_attributes(attributes)

    # allow mounted interceptors to process teh values, and re-mount them
    #
      deepest_first = mounted.sort_by{|mnt| mnt._key.size}.reverse

      deepest_first.each do |mnt|
        value = @attributes.get(mnt._key)
        mnt._set(value) if mnt.respond_to?(:_set)
        @attributes.set(mnt._key => mnt)
      end

    # teh result
    #
      @attributes
    end

    def attributes=(attributes)
      update_attributes(attributes)
    end

    def update_attributes!(*args, &block)
      update_attributes(*args, &block)
    ensure
      save!
    end

    def merge_attributes(attributes)
      Map.for(attributes).depth_first_each do |keys, value|
        unless value.is_a?(Hash)
          %w( to_dao to_map attributes ).each do |method|
            if value.respond_to?(method)
              converted = value.send(method)
              value = converted
              break
            end
          end
        end
        keys == [nil] ? @attributes.set(value) : @attributes.set(keys, value)
      end
    end

    def set(*args, &block)
      update_attributes(*args, &block)
    end

    def has?(*key)
      key = key_for(key)
      tester = key.join('__') + '?'
      if respond_to?(tester)
        send(tester)
      else
        @attributes.has?(key)
      end
    end

    def get(*key)
      key = key_for(key)
      getter = key.join('__')
      if respond_to?(getter)
        send(getter)
      else
        @attributes.get(key)
      end
    end

    def [](key)
      get(key)
    end

    def []=(key, val)
      set(key, val)
    end

    def method_missing(method, *args, &block)
      re = /^([^=!?]+)([=!?])?$/imox

      matched, key, suffix = re.match(method.to_s).to_a
      
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

  ## id support 
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

  ## mixin controller support
  #
    module_eval(&ControllerSupport)

  ## mixin callback support
  #
    module_eval(&CallbackSupport)

  ## mixin view support
  #
    module_eval(&ViewSupport)

  ##
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

  ## misc
  #
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

    def key_for(key)
      Dao.key_for(key)
    end

    def errors
      validator.errors
    end

    def status
      validator.status
    end

    def model_name
      self.class.model_name
    end

    def form
      @form
    end

    def helper
      @helper ||= ::Helper.new
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
      "#{ self.class.name }(#{ @attributes.inspect.chomp })"
    end

    def to_s
      inspect
    end
  end
end
