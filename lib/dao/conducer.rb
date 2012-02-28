# -*- encoding : utf-8 -*-
module Dao
##
#
  Dao.load('conducer/attributes.rb')
  Dao.load('conducer/active_model.rb')
  Dao.load('conducer/controller_support.rb')
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
    ].each{|attr| fattr(attr)}

    def init(*args, &block)
      controllers, args = args.partition{|arg| arg.is_a?(ActionController::Base)}
      actions, args = args.partition{|arg| arg.is_a?(Action)}
      hashes, args = args.partition{|arg| arg.is_a?(Hash)}

      @name = self.class.model_name.singular.sub(/_+$/, '')
      @attributes = Attributes.for(self)
      @form = Form.for(self)
      @params = Map.new

      @errors = validator.errors
      @status = validator.status

      set_controller(controllers.shift || Dao.current_controller || Dao.mock_controller)
      set_action(actions.shift) unless actions.empty?

      hashes.each{|hash| @params.apply(hash)}
    end

    def initialize(*args, &block)
      update_attributes(params)
    end

  ## accessors
  #
    def update_attributes(*args, &block)
      params =
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

      (@setting ||= []).push(params)
      recursion_depth = @setting.size - 1

      begin
        Dao.tree_walk(params) do |key, value|
          unless recursion_depth > 0
            handler = key.join('__') + '='
            if respond_to?(handler)
              send(handler, value)
              throw(:tree_walk, :next_sibling)
            end

            if((handler = @attributes.get(key)).respond_to?(:_update_attributes))
              handler._update_attributes(:value => value)
              throw(:tree_walk, :next_sibling)
            end
          end

          @attributes.set(key, value)
        end
      ensure
        @setting.pop
      end
    end

    def attributes=(attributes)
      update_attributes(attributes)
    end

    def update_attributes!(*args, &block)
      update_attributes(*args, &block)
    ensure
      save!
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
          has?(key) ? get(key) : super
      end
    end

  ## id support 
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

  ## mixin controller support
  #
    module_eval(&ControllerSupport)

  ## mixin view support
  #
    module_eval(&ViewSupport)

  ##
  #
    def save
      NotImplementedError
    end
    
    def save!
      raise!(:validation_error) unless !!save 
      true
    end

    def destroy
      NotImplementedError
    end

    def destroy!
      raise!(:deletion_error) unless !!destroy
      true
    end

  ## misc
  #
    def mount(object, *args, &block)
      object.mount(self, *args, &block)
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

    def raise!(*args, &block)
      self.class.raise!(*args, &block)
    end

    def as_json
      @attributes
    end

    def conducer
      self
    end

    def inspect
      "#{ self.class.name }(#{ @attributes.inspect.chomp })"
    end
  end
end
