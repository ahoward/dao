# -*- encoding : utf-8 -*-
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
          record_to_dao(args.shift, *args)
        else
          @to_dao ||= (
            column_names ### + reflect_on_all_associations.map(&:name)
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

      # get base to_dao from class
      #
        base = model.to_dao

      # opts
      # 
        opts = %w( include includes with exclude excludes without )

        extract_options =
          proc do |array|
            last = array.last
            if last.is_a?(Hash)
              last = Dao.map(last)
              if opts.any?{|opt| last.has_key?(opt)}
                array.pop
                break(last)
              end
            end
            Map.new
          end

      # handle case where options are bundled in args...
      #
        options ||= extract_options[args]

      # use base options iff none provided
      #
        base_options = extract_options[base]
        if options.blank? and !base_options.blank?
          options = base_options
        end

      # refine the args with includes iff found in options
      #
        if options.has_key?(:include) or options.has_key?(:includes) or options.has_key?(:with)
          args.replace(base) if args.empty?
          args.push(options[:include]) if options[:include]
          args.push(options[:includes]) if options[:includes]
          args.push(options[:with]) if options[:with]
        end

      # take passed in args or model defaults
      #
        list = args.empty? ? base : args
        list = column_names if list.empty?

      # okay - go!
      #
        list.each do |attr|
          if attr.is_a?(Array)
            related, *argv = attr
            v = record.send(related)
            value = v.respond_to?(:to_dao) ? v.to_dao(*argv) : v
            map[related] = value
            next
          end

          if attr.is_a?(Hash)
            attr.each do |rel, _argv|
              v = record.send(rel)
              value = v.respond_to?(:to_dao) ? v.to_dao(*_argv) : v
              map[rel] = value
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

      # refine the map with excludes iff passed as options
      #
        if options.has_key?(:exclude) or options.has_key?(:excludes) or options.has_key?(:without)
          [options[:exclude], options[:excludes], options[:without]].each do |paths|
            paths = Array(paths)
            next if paths.blank?
            paths.each do |path|
              map.rm(path)
            end
          end
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
