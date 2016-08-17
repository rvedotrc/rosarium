module Rosarium

  class SimplePromise

    def self.defer
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
      @resolving = false
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @on_resolution = []
    end

    def state
      synchronize { @state }
    end

    def value
      wait
      synchronize { @value }
    end

    def reason
      wait
      synchronize { @reason }
    end

    def inspect
      synchronize do
        r = { state: @state }
        r[:value] = @value if @state == :fulfilled
        r[:reason] = @reason if @state == :rejected
        r
      end
    end

    def fulfilled?
      state == :fulfilled
    end

    def rejected?
      state == :rejected
    end

    def value!
      wait
      synchronize do
        if @state == :rejected
          raise @reason
        else
          @value
        end
      end
    end

    private

    def wait
      on_resolution do
        synchronize { @condition.broadcast }
      end

      synchronize do
        loop do
          return if @state == :fulfilled or @state == :rejected
          @condition.wait @mutex
        end
      end
    end

    def synchronize
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

      synchronize do
        if @state == :pending and not @resolving
          if value.kind_of? SimplePromise
            @resolving = true
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

      synchronize do
        @value = other.value
        @reason = other.reason
        @state = other.state
        @resolving = false
        callbacks.concat @on_resolution
        @on_resolution.clear
      end

      callbacks.each {|c| EXECUTOR.submit { c.call } }
    end

    protected

    def on_resolution(&block)
      immediate = synchronize do
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
