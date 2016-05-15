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

    def self.execute(&block)
      deferred = defer
      EXECUTOR.submit do
        begin
          deferred.resolve block.call
        rescue Exception => e
          deferred.reject e
        end
      end
      deferred.promise
    end

    def self.all_settled(promises)
      return resolve([]) if promises.empty?

      deferred = defer
      promises = promises.dup

      check = Proc.new do
        if promises.all? {|promise| promise.fulfilled? or promise.rejected?}
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

      do_reject = Proc.new {|reason| deferred.reject reason}
      do_fulfill = Proc.new do
        if promises.all?(&:fulfilled?)
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

      on_resolution do
        begin
          deferred.resolve(
            if fulfilled?
              on_fulfilled.call value
            else
              on_rejected.call reason
            end
          )
        rescue Exception => e
          deferred.reject e
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
