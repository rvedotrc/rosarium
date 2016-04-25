module MyConcurrent
  
  class Promise

    def self.fulfill(value)
      o = new
      o.fulfill(value)
      o
    end

    def self.reject(reason)
      o = new
      o.reject(reason)
      o
    end

    def initialize
      @state = :new
    end

    def fulfill(value)
      @value = value
    end

    def reject(reason)
      @reason = reason
    end

    def state
      @reason ? :rejected : :fulfilled
    end

    def fulfilled?
      state == :fulfilled
    end

    def rejected?
      state == :rejected
    end

    def value
      @value
    end

    def reason
      @reason
    end

  end
  
end
