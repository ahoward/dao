module Dao::Current
  Methods = proc do
  end

  ClassMethods = proc do
    def current_controller
      @current_controller ||= (
        if defined?(@controller)
          @controller
        else
          Dao.current_controller || Dao.mock_controller
        end
      )
    end

    %w( request response session ).each do |attr|
      instance_eval <<-__, __FILE__, __LINE__
        def current_#{ attr }
          @current_#{ attr } ||= current_controller.instance_eval{ #{ attr } }
        end
      __
    end

    %w( current_user effective_user real_user ).each do |attr|
      instance_eval <<-__, __FILE__, __LINE__
        def #{ attr }
          @#{ attr } ||= current_controller.instance_eval{ #{ attr } }
        end
        def #{ attr }=(value)
          @#{ attr } = value
        end
      __
    end
  end

  InstanceMethods = proc do
    def current_controller
      @current_controller ||= (
        if defined?(@controller)
          @controller
        else
          Dao.current_controller || Dao.mock_controller
        end
      )
    end

    %w( request response session ).each do |attr|
      module_eval <<-__, __FILE__, __LINE__
        def current_#{ attr }
          @current_#{ attr } ||= current_controller.instance_eval{ #{ attr } }
        end
      __
    end

    %w( current_user effective_user real_user ).each do |attr|
      module_eval <<-__, __FILE__, __LINE__
        def #{ attr }
          @#{ attr } ||= current_controller.instance_eval{ #{ attr } }
        end
        def #{ attr }=(value)
          @#{ attr } = value
        end
      __
    end
  end

  def self.included(other)
    other.send(:instance_eval, &ClassMethods)
    other.send(:class_eval, &InstanceMethods)
    super
  end
end
