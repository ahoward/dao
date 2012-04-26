module Dao
  class Conducer
    class << Conducer
      fattr(:collection_class)

      def build_collection_class!
        conducer_class = self
        collection_class = const_set(:Collection, Class.new(Collection){})
        collection_class.conducer_class = conducer_class
        conducer_class.collection_class = collection_class
      end

      def collection_for(models, *args, &block)
        collection_class.load(models, *args, &block)
      end
    end

    class Collection < ::Array
      class << Collection
        fattr(:conducer_class)

        def load(*args, &block)
          new.tap{|collection| collection.load(*args, &block)}
        end
      end

      fattr(:models)

      def conducer_class
        self.class.conducer_class
      end

      def load(models, *args, &block)
        block ||= proc{|model| conducer_class.new(model, *args) }
        (self.models = models).each{|model| self << block.call(model, *args)}
        self
      end

      def method_missing(method, *args, &block)
        return(models.send(method, *args, &block)) if models.respond_to?(method)
        super
      end
    end
  end
end
