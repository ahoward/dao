module Dao
  class Conducer
    include ActiveModel::Naming
    include ActiveModel::Conversion
    extend ActiveModel::Translation

=begin
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization
    include ActiveModel::Dirty
    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Observing
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include ActiveModel::Validations
    extend ActiveModel::Callbacks
    define_model_callbacks(:save, :create, :update, :destroy)
    define_model_callbacks(:reset, :initialize, :find, :touch)
    include ActiveModel::Validations::Callbacks
=end

    class << Conducer
      def model_name(*args)
        return send('model_name=', args.first.to_s) unless args.empty?
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

        suffixes = /(Conducer|Resource|Importer|Presenter|Conductor|Cell)\Z/o

        name = self.name.to_s
        name.sub!(suffixes, '') unless name.sub(suffixes, '').blank?
        name.sub!(/(:|_)+$/, '')

        model_name_for(name)
      end

      def collection_name
        @collection_name ||= model_name.plural.to_s
      end
      alias_method('table_name', 'collection_name')

      def collection_name=(collection_name)
        @collection_name = collection_name.to_s
      end
      alias_method('set_collection_name', 'collection_name=')
      alias_method('table_name=', 'collection_name=')
      alias_method('set_table_name', 'collection_name=')
    end
    
    def persisted
      !!(defined?(@persisted) ? @persisted : @model ? @model.persisted? : !id.blank?)
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
      !!(defined?(@new_record) ? @new_record : @model ? @model.new_record? : id.blank?)
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
      !!(defined?(@destroyed) ? @destroyed : @model ? @model.destroyed : id.blank?)
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
      get(key)
    end

  end
end
