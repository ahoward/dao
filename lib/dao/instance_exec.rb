module Dao
  module InstanceExec
    Code = lambda do
      unless Object.new.respond_to?(:instance_exec)
        module InstanceExecHelper; end
        include InstanceExecHelper

        def instance_exec(*args, &block)
          begin
            old_critical, Thread.critical = Thread.critical, true
            n = 0
            n += 1 while respond_to?(mname="__instance_exec_#{ n }__")
            InstanceExecHelper.module_eval{ define_method(mname, &block) }
          ensure
            Thread.critical = old_critical
          end
          begin
            ret = send(mname, *args)
          ensure
            InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
          end
          ret
        end
      end
    end

    def InstanceExec.included(other)
      other.module_eval(&Code)
      super
    end

    def InstanceExec.extend_object(other)
      other.instance_eval(&Code)
      super
    end
  end
end
