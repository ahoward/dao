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
        if args.first.is_a?(Base)
          record_to_dao(record = args.shift, *args)
        else
          @to_dao ||= (
            names = column_names ### + reflect_on_all_associations.map(&:name)
          )
          @to_dao = Array(args) unless args.empty?
          @to_dao
        end
      end

      def Base.to_dao=(*args)
        to_dao(*args)
      end

      def Base.record_to_dao(record, *args)
      # setup for eff'ing madness        
      #
        model = record.class
        map = Dao.map
        map[:model] = model.name.underscore
        map[:id] = record.id

      # yank out options if they are patently obvious...
      #
        if args.size == 2 and args.first.is_a?(Array) and args.last.is_a?(Hash)
          options = Dao.map(args.last)
          args = args.first
        else
          options = nil
        end

      # search for options inside args...
      #
        if options.nil?
          last = args.last
          options = Dao.map

          if last.is_a?(Hash)
            last = Dao.map(last)
            keys = %w( include includes with )
            if keys.any?{|key| last.has_key?(key)}
              options.update(last)
              args.pop
            end
          end
        end

      # refine the list with includes iff passed as options
      #
        if options.has_key?(:include) or options.has_key?(:includes) or options.has_key?(:with)
          args.replace(model.to_dao) if args.empty?
          args.push(options[:include]) if options[:include]
          args.push(options[:includes]) if options[:includes]
          args.push(options[:with]) if options[:with]
        end

      # take passed in args or model defaults
      #
        list = args.empty? ? model.to_dao : args

      # okay - go!
      #
        list.each do |attr|
          if attr.is_a?(Array)
            related, *argv = attr
            value = record.send(related).to_dao(*argv)
            map[related] = value
            next
          end

          if attr.is_a?(Hash)
            attr.each do |related, argv|
              value = record.send(related).to_dao(*argv)
              map[related] = value
            end
            next
          end

          value = record.send(attr)

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

      def to_dao(*args)
        record = self
        model = record.class
        model.record_to_dao(record, *args)
      end
      ### alias_method('to_h', 'to_dao')
      ### alias_method('to_map', 'to_dao') ### HACK
    end
  end

end
