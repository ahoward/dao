module Dao
  class Dao::Error < ::StandardError
  end

  class Dao::Error::Result < Error
    attr_accessor :result

    def self.for(result, *args, &block)
      error = new(*args, &block)
      error.result = result
      error
    end
  end

  class Dao::Error::Status < Error
    attr_accessor :status

    def self.for(status, *args, &block)
      error = new(*args, &block)
      error.status = status
      error
    end
  end
end
