begin
  ActiveRecord
  ActiveRecord::Base
rescue NameError
  nil
end

if defined?(ActiveRecord)

  module ActiveRecord
    class Base
      def Base.to_dao(*args)
        @to_dao ||= (
          names = column_names ### + reflect_on_all_associations.map(&:name)
        )
        @to_dao = Array(args) unless args.empty?
        @to_dao
      end

      def Base.to_dao=(*args)
        to_dao(*args)
      end

      def to_dao(*args)
        model = self.class
        map = Dao.map(:type => model.name.underscore)

        list = args.empty? ? model.to_dao : args

        list.each do |attr|
          if attr.is_a?(Array)
            attr, *argv = attr
            value = send(attr).to_dao(*argv)
            map[attr] = value
            next
          end

          value = send(attr)

          if value.respond_to?(:to_dao)
            map[attr] = value.to_dao
            next
          end

          if value.is_a?(Array)
            map[attr] = value.map{|val| val.respond_to?(:to_dao) ? val.to_dao : val}
            next
          end

          map[attr] = value
        end

        if map.has_key?(:_id) and not map.has_key?(:id)
          map[:id] = map[:_id]
        end

        map
      end
      alias_method 'to_h', 'to_dao'
      ### alias_method 'to_map', 'to_dao' ### HACK
    end
  end

end
