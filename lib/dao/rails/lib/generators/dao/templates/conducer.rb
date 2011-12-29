# -*- encoding : utf-8 -*-
<%

  class_name = @conducer_name.camelize
  model_name = class_name.sub(/Conducer/, '') 

-%>
class <%= class_name %> < Dao::Conducer
## class_methods
#
  class << <%= class_name %>
    def all(params = {})
      records = <%= model_name %>.paginate(params)

      records.map! do |record|
        new(record.attributes)
      end
    end

    def find(id)
      raise NotImplementedError, <<-__
        this needs to return an instance based on the id
      __
    end
  end

## instance_methods
#
  def initialize
  end

  def save
    return(false) unless valid?

    raise NotImplementedError, <<-__
      this needs to
        - persist data to the db and get a new id
        - set the id on the object : @attributes.set(:id => id)
        - return true or false
    __

    true
  end

  def destroy
    id = self.id
    if id

      raise NotImplementedError, <<-__
        this needs to
          - un-persist data from the db
          - set the id on the object to nil : @attributes.rm(:id)
          - return this id of the destroyed object 
      __

    end
    id
  end
end
