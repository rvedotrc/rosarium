module Rosarium

  class Promise

    DEFAULT_ON_FULFILL = Proc.new {|value| value}
    DEFAULT_ON_REJECT = Proc.new {|reason| raise reason}

    private_class_method :new

    def self.defer
      promise = new

      resolver = ->(value) { promise.send(:try_settle, value, nil) }

      rejecter = lambda do |reason|
        raise "reason must be an Exception" unless reason.is_a?(Exception)

        promise.send(:try_settle, nil, reason)
      end

      Deferred.new(promise, resolver, rejecter)
    end

    def self.resolve(value)
      if value.kind_of? Promise
        return value
      end

      deferred = defer
      deferred.resolve(value)
      deferred.promise
    end

    def self.reject(reason)
      deferred = defer
      deferred.reject(reason)
      deferred.promise
    end

    def self.execute(&block)
      @@resolved.then(&block)
    end

    def self.all_settled(promises)
      return resolve([]) if promises.empty?

      deferred = defer
      promises = promises.dup

      waiting_for = promises.count
      mutex = Mutex.new

      check = Proc.new do
        # Includes both fulfilled and rejected, so always hits zero eventually
        if mutex.synchronize { (waiting_for -= 1) == 0 }
          deferred.resolve promises
        end
      end

      promises.each do |promise|
        promise.then(check, &check)
      end

      deferred.promise
    end

    def self.all(promises)
      return resolve([]) if promises.empty?

      deferred = defer
      promises = promises.dup

      waiting_for = promises.count
      mutex = Mutex.new

      do_reject = Proc.new {|reason| deferred.reject reason}
      do_fulfill = Proc.new do
        # Only fulfilled (not rejected), so hits zero iff all promises were fulfilled
        if mutex.synchronize { (waiting_for -= 1) == 0 }
          deferred.resolve(promises.map &:value)
        end
      end

      promises.each do |promise|
        promise.then(do_reject, &do_fulfill)
      end

      deferred.promise
    end

    def then(on_rejected = nil, &on_fulfilled)
      deferred = self.class.defer

      on_fulfilled ||= DEFAULT_ON_FULFILL
      on_rejected ||= DEFAULT_ON_REJECT

      when_settled do
        EXECUTOR.submit do
          begin
            deferred.resolve(
              if fulfilled?
                # User-supplied code
                on_fulfilled.call value
              else
                # User-supplied code
                on_rejected.call reason
              end
            )
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

    public

    def initialize
      @state = :pending
      @resolving = false
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @when_settled = []
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
      when_settled do
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

    def try_settle(value, reason)
      callbacks = []
      add_when_settled = false

      synchronize do
        if @state == :pending and not @resolving
          if value.kind_of? Promise
            @resolving = true
            add_when_settled = true
          elsif reason.nil?
            @value = value
            @state = :fulfilled
            callbacks.concat @when_settled
            @when_settled.clear
          else
            @reason = reason
            @state = :rejected
            callbacks.concat @when_settled
            @when_settled.clear
          end
        end
      end

      if add_when_settled
        value.when_settled { copy_settlement_from value }
      end

      callbacks.each { |c| EXECUTOR.submit(&c) }
    end

    def copy_settlement_from(other)
      callbacks = []

      synchronize do
        @value = other.value
        @reason = other.reason
        @state = other.state
        @resolving = false
        callbacks.concat @when_settled
        @when_settled.clear
      end

      callbacks.each { |c| EXECUTOR.submit(&c) }
    end

    protected

    def when_settled(&block)
      immediate = synchronize do
        if @state == :fulfilled or @state == :rejected
          true
        else
          @when_settled << block
          false
        end
      end

      block.call if immediate

      nil
    end

    @@resolved = resolve(nil)

  end

end
