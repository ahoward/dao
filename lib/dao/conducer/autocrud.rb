module Dao
  class << Conducer
    def autocrud!
      include(Conducer::AutoCRUD)
    end
    alias_method('crud!', 'autocrud!')
  end

  class Conducer
    module AutoCRUD
      Code = proc do
        class << self
          def db
            @db ||= Db.instance
          end

          def db_collection
            db.collection(collection_name)
          end

          def all(*args)
            hashes = db_collection.all()
            hashes.map{|hash| new(hash)}
          end

          def find(*args)
            options = args.extract_options!.to_options!
            id = args.shift || options[:id]
            hash = db_collection.find(id)
            new(hash) if hash
          end
        end

        def save
          id = self.class.db_collection.save(@attributes)
          @attributes.set(:id => id)
          true
        end

        def destroy
          id = self.id
          if id
            self.class.db_collection.destroy(id)
            @attributes.rm(:id)
          end
          id
        end
      end

      def AutoCRUD.included(other)
        super
      ensure
        other.module_eval(&Code)
      end
    end
  end
end
