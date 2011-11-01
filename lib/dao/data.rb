module Dao
  class Data < ::Map
  # look good for inspect
  #
    def inspect
      Dao.json_for(self)
    end

  # support updates with dao-ish objects
  #
    add_conversion_method!(:to_dao)
    add_conversion_method!(:as_dao)

    def update(*args, &block)
      if args.size==1 and args.first.respond_to?(:to_dao)
        to_dao = args.first.to_dao
        return super(to_dao)
      end
      super
    end
  end
end
