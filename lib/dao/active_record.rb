begin
  ActiveRecord
  ActiveRecord::Base
rescue NameError
  nil
end

if defined?(ActiveRecord)

  module ActiveRecord
    module ToDao
      module ClassMethods
        def to_dao(*args)

          @to_dao ||= (
            column_names # + reflect_on_all_associations.map(&:name)
          ).map{|name| name.to_s}

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

        def to_dao=(*args)
          to_dao(*args)
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
        #alias_method 'to_map', 'to_dao' ### HACK
      end
    end

    if defined?(ActiveRecord::Base)
      ActiveRecord::Base.send(:extend, ToDao::ClassMethods)
      ActiveRecord::Base.send(:include, ToDao::InstanceMethods)
    end
  end

end
