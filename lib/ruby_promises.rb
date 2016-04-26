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
      @on_resolution = []
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
      resolve(value, nil)
    end

    def reject(reason)
      raise "reason must be an Exception" unless reason.kind_of? Exception
      resolve(nil, reason)
    end

    private

    def resolve(value, reason)
      callbacks = []

      synchronized do
        if @state != :fulfilled and @state != :rejected
          if reason.nil?
            @value = value
            @state = :fulfilled
          else
            @reason = reason
            @state = :rejected
          end

          callbacks.concat @on_resolution
          @on_resolution.clear
        end
      end

      callbacks.each(&:call)
    end

    def on_resolution(&block)
      immediate = synchronized do
        if @state == :fulfilled or @state == :rejected
          true
        else
          @on_resolution << block
          false
        end
      end

      block.call if immediate

      nil
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

    def then(on_rejected = nil, &on_fulfilled)
      deferred = self.class.new_deferred

      on_fulfilled ||= Proc.new {|value| value}
      on_rejected ||= Proc.new {|reason| raise reason}

      on_resolution do
        if fulfilled?
          begin
            deferred.fulfill(on_fulfilled.call value)
          rescue Exception => e
            deferred.reject e
          end
        else
          begin
            deferred.fulfill(on_rejected.call reason)
          rescue Exception => e
            deferred.reject e
          end
        end
      end

      deferred.promise
    end

    def rescue(&block)
      self.then(block)
    end

    alias_method :catch, :rescue
    alias_method :on_error, :rescue

  end

end
