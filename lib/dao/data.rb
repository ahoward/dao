module Dao
  class Data < ::Map
    add_conversion_method!(:to_dao)
    add_conversion_method!(:as_dao)

    def update(*args, &block)
      if args.size==1 and args.first.respond_to?(:to_dao)
        to_dao = args.first.to_dao
        update(to_dao)
        return(to_dao)
      end
      super
    end
  end
end
