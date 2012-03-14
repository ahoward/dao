# -*- encoding : utf-8 -*-
<%

  class_name = @conducer_name.camelize
  model_name = class_name.sub(/Conducer/, '') 

-%>

class <%= class_name %> < Dao::Conducer
  def initialize(user, model, params = {})
    @user = user
    @model = model

    update_attributes(
      :user  => @user.attributes,
      :model => @model.attributes,

      :foo  => 'bar'
    )

    id!(@model.id) unless @model.new_record?

    mount(Dao::Upload, :logo, :placeholder => (@model.logo.try(:url) || 'http://placeholder.com/image.png'))

    case action
      when 'new', 'create'
        @attributes.email = @user.email
        @model.field = @page.field

        update_attributes(params)

      when 'edit', 'update', 'show'
        @attributes.email = @user.email
        @model.field = @page.field

        update_attributes(params)
    end
  end


  validates_presence_of :something

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
