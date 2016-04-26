module MyConcurrent

  class SimplePromise

    def self.new_deferred
      promise = new
      resolver = promise.method :resolve
      rejecter = promise.method :reject

      class <<promise
        undef :resolve
        undef :reject
      end

      Deferred.new(promise, resolver, rejecter)
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

    def resolve(value)
      _resolve(value, nil)
    end

    def reject(reason)
      raise "reason must be an Exception" unless reason.kind_of? Exception
      _resolve(nil, reason)
    end

    private

    def _resolve(value, reason)
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

end
