module Dao
  class Data < ::Map
    add_conversion_method!(:to_dao)
    add_conversion_method!(:as_dao)
  end
end


=begin
    %w( to_dao as_dao ).each do |method|
      module_eval <<-__, __FILE__, __LINE__
        def #{ method }(object, *args, &block)
          case object
            when Array
              object.map{|element| Data.#{ method }(element)}

            else
              if object.respond_to?(:#{ method })
                object.send(:#{ method }, *args, &block)
              else
                object
              end
          end
        end
      __
    end
=end

=begin
    IdKeys =
      %w( id uuid guid ).map{|key| [key, key.to_sym, "_#{ key }", "_#{ key }".to_sym]}.flatten

    def id
      IdKeys.each{|key| return self[key] if has_key?(key)}
      return nil
    end

    def has_id?
      IdKeys.each{|key| return true if has_key?(key)}
      return false
    end

    def new?
      !has_id?
    end

    def new_record?
      !has_id?
    end

    def model_name
      path.to_s
    end

    def slug
      Slug.for(path)
    end
=end
