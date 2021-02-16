# frozen_string_literal: true

module Rosarium
  class Promise

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
      return value if value.is_a? Promise

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
      @resolved.then(&block)
    end

    def self.all_settled(promises)
      return resolve([]) if promises.empty?

      deferred = defer
      promises = promises.dup

      waiting_for = promises.count
      mutex = Mutex.new

      check = proc do
        # Includes both fulfilled and rejected, so always hits zero eventually
        if mutex.synchronize { (waiting_for -= 1) == 0 }
          deferred.resolve promises
        end
      end

      promises.each do |promise|
        promise.send(:when_settled, &check)
      end

      deferred.promise
    end

    def self.all(promises)
      return resolve([]) if promises.empty?

      deferred = defer
      promises = promises.dup

      waiting_for = promises.count
      mutex = Mutex.new

      check = lambda do |promise|
        if promise.fulfilled?
          # Hits zero iff all promises were fulfilled
          if mutex.synchronize { (waiting_for -= 1) == 0 }
            deferred.resolve(promises.map(&:value))
          end
        else
          deferred.reject(promise.reason)
        end
      end

      promises.each do |promise|
        promise.send(:when_settled) { check.call(promise) }
      end

      deferred.promise
    end

    def initialize
      @state = :pending
      @copy_outcome_from = false
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
        raise @reason if @state == :rejected
        @value
      end
    end

    def then(on_rejected = nil, &on_fulfilled)
      deferred = self.class.defer

      when_settled do
        EXECUTOR.submit do
          begin
            deferred.resolve(
              if fulfilled?
                # User-supplied code
                on_fulfilled ? on_fulfilled.call(value) : value
              else
                # User-supplied code
                on_rejected ? on_rejected.call(reason) : raise(reason)
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

    alias catch rescue
    alias on_error rescue

    private

    def wait
      synchronize do
        loop do
          return if @state != :pending
          @condition.wait @mutex
        end
      end
    end

    def synchronize(&block)
      @mutex.synchronize(&block)
    end

    # Can be called more than once
    def try_settle(value, reason)
      settle_with = nil

      synchronize do
        return if @state != :pending || @copy_outcome_from

        if value.is_a? Promise
          @copy_outcome_from = true
        elsif reason.nil?
          settle_with = [value, nil]
        else
          settle_with = [nil, reason]
        end
      end

      if settle_with
        settle(*settle_with)
      else
        value.when_settled do
          if value.fulfilled?
            settle(value.value, nil)
          else
            settle(nil, value.reason)
          end
        end
      end
    end

    # Only called once
    def settle(value, reason)
      synchronize do
        @state = (reason ? :rejected : :fulfilled)
        @value = value
        @reason = reason
        @copy_outcome_from = false
        @condition.broadcast
        @when_settled.slice!(0, @when_settled.length)
      end.each(&:call)
    end

    protected

    def when_settled(&block)
      immediate = synchronize do
        if @state == :fulfilled || @state == :rejected
          true
        else
          @when_settled << block
          false
        end
      end

      block.call if immediate

      nil
    end

    @resolved = resolve(nil)

  end
end
