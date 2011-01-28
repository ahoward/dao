begin
  MongoMapper
rescue NameError
  nil
end

if defined?(MongoMapper)

  module MongoMapper
    module ToDao
      module ClassMethods
        def to_dao(*args)

          unless defined?(@to_dao)
            @to_dao = column_names.map{|name| name.to_s}
          end

          unless args.empty?
            @to_dao.clear
            args.flatten.compact.each do |arg|
              @to_dao.push(arg.to_s)
            end
            @to_dao.uniq!
            @to_dao.map!{|name| name.to_s}
          end

          @to_dao
        end
      end

      module InstanceMethods
        def to_dao(*args)
          hash = Dao.hash
          model = self.class

          attrs = args.empty? ? model.to_dao : args

          attrs.each do |attr|
            value = send(attr)

            if value.respond_to?(:to_dao)
              hash[attr] = value.to_dao
              next
            end

            if value.is_a?(Array)
              hash[attr] = value.map{|val| val.respond_to?(:to_dao) ? val.to_dao : val}
              next
            end

            hash[attr] = value
          end

          if hash.has_key?(:_id) and not hash.has_key?(:id)
            hash[:id] = hash[:_id]
          end

          hash
        end
        alias_method 'to_h', 'to_dao'
      end
    end

    MongoMapper::Document::ClassMethods.send(:include, ToDao::ClassMethods)
    MongoMapper::Document::InstanceMethods.send(:include, ToDao::InstanceMethods)
    MongoMapper::EmbeddedDocument::ClassMethods.send(:include, ToDao::ClassMethods)
    MongoMapper::EmbeddedDocument::InstanceMethods.send(:include, ToDao::InstanceMethods)
  end

end
