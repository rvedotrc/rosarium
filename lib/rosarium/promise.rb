module Rosarium

  class Promise < SimplePromise

    DEFAULT_ON_FULFILL = Proc.new {|value| value}
    DEFAULT_ON_REJECT = Proc.new {|reason| raise reason}

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

    @@resolved = resolve(nil)
    def self.execute(&block)
      @@resolved.then { block.call }
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
        promise.then(check) { check.call }
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
        promise.then(do_reject) { do_fulfill.call }
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

  end

end
