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
      @condition = ConditionVariable.new
      @on_resolution = []
    end

    def state
      synchronized { @state }
    end

    def value
      wait
      synchronized { @value }
    end

    def reason
      wait
      synchronized { @reason }
    end

    def fulfilled?
      state == :fulfilled
    end

    def rejected?
      state == :rejected
    end

    def value!
      wait
      synchronized do
        if @state == :rejected
          raise @reason
        else
          @value
        end
      end
    end

    def wait
      on_resolution do
        @mutex.synchronize { @condition.broadcast }
      end

      @mutex.synchronize do
        loop do
          return if @state == :fulfilled or @state == :rejected
          @condition.wait @mutex
        end
      end
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
      add_on_resolution = false

      synchronized do
        if @state == :pending
          if value.kind_of? SimplePromise
            @state = :resolving
            add_on_resolution = true
          elsif reason.nil?
            @value = value
            @state = :fulfilled
            callbacks.concat @on_resolution
            @on_resolution.clear
          else
            @reason = reason
            @state = :rejected
            callbacks.concat @on_resolution
            @on_resolution.clear
          end
        end
      end

      if add_on_resolution
        value.on_resolution { copy_resolution_from value }
      end

      callbacks.each {|c| EXECUTOR.submit { c.call } }
    end

    def copy_resolution_from(other)
      callbacks = []

      synchronized do
        if @state == :resolving
          @value = other.value
          @reason = other.reason
          @state = other.state
          callbacks.concat @on_resolution
          @on_resolution.clear
        end
      end

      callbacks.each {|c| EXECUTOR.submit { c.call } }
    end

    protected

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
