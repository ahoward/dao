module Dao
## CRUD support
#
  class Conducer
    module CRUD
      Code = proc do
        class << self
          def db
            Db.instance
          end

          def collection
            db[collection_name]
          end

          def all(*args)
            hashes = collection.all()
            hashes.map{|hash| new(hash)}
          end

          def find(*args)
            options = args.extract_options!.to_options!
            id = args.shift || options[:id]
            hash = collection.find(id)
            new(hash) if hash
          end
        end

        def save
          run_callbacks :save do
            return(false) unless valid?
            id = self.class.collection.save(@attributes)
            @attributes.set(:id => id)
            true
          end
        ensure
          @new_record = false
        end

        def destroy
          id = self.id
          if id
            self.class.collection.destroy(id)
            @attributes.rm(:id)
          end
          id
        ensure
          @destroyed = true
        end
      end

      def CRUD.included(other)
        super
      ensure
        other.module_eval(&Code)
      end
    end
  end

## dsl for auto-crud
#
  class Conducer
    class << self
      def crud
        include(Conducer::CRUD)
      end
      alias_method('crud!', 'crud')
      alias_method('autocrud!', 'crud')
    end
  end
  #Conducer::send(:include, Conducer::CRUD)
end
