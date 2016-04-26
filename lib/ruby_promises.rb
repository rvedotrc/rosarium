module MyConcurrent

  class SimplePromise

    def self.new_deferred
      promise = new
      fulfiller = promise.method :fulfill
      rejecter = promise.method :reject

      class <<promise
        undef :fulfill
        undef :reject
      end

      Deferred.new(promise, fulfiller, rejecter)
    end

    def initialize
      @state = :pending
      @mutex = Mutex.new
    end

    def state
      synchronized { @state }
    end

    def value
      synchronized { @value }
    end

    def reason
      synchronized { @reason }
    end

    def fulfilled?
      state == :fulfilled
    end

    def rejected?
      state == :rejected
    end

    private

    def synchronized
      @mutex.synchronize { yield }
    end

    public

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

  end

  class Deferred

    def initialize(promise, fulfiller, rejecter)
      @promise = promise
      @fulfiller = fulfiller
      @rejecter = rejecter
    end

    def promise
      @promise
    end

    def fulfill(value)
      @fulfiller.call(value)
    end

    def reject(reason)
      @rejecter.call(reason)
    end

  end

  class Promise < SimplePromise

    def self.defer
      new_deferred
    end

    def self.fulfill(value)
      deferred = new_deferred
      deferred.fulfill(value)
      deferred.promise
    end

    def self.reject(reason)
      deferred = new_deferred
      deferred.reject(reason)
      deferred.promise
    end

    def self.execute(&block)
      deferred = new_deferred
      t = Thread.new do
        begin
          deferred.fulfill block.call
        rescue Exception => e
          deferred.reject e
        end
      end
      deferred.promise
    end

  end

end
