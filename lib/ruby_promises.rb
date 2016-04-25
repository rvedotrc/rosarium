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
      @mutex = Mutex.new
    end

    def fulfill(value)
      synchronized do
        if @state != :fulfilled and @state != :rejected
          @value = value
          @state = :fulfilled
        end
      end
    end

    def reject(reason)
      synchronized do
        if @state != :fulfilled and @state != :rejected
          @reason = reason
          @state = :rejected
        end
      end
    end

    def state
      synchronized { @state }
    end

    def fulfilled?
      state == :fulfilled
    end

    def rejected?
      state == :rejected
    end

    def value
      synchronized { @value }
    end

    def reason
      synchronized { @reason }
    end

    private

    def synchronized
      @mutex.synchronize { yield }
    end

  end
  
end
