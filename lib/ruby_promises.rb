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
      @state = :pending
    end

    def fulfill(value)
      @value = value
      @state = :fulfilled
    end

    def reject(reason)
      @reason = reason
      @state = :rejected
    end

    def state
      @state
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
