module MyConcurrent

  class Promise < SimplePromise

    def self.defer
      new_deferred
    end

    def self.resolve(value)
      if value.kind_of? Promise
        return value
      end

      deferred = new_deferred
      deferred.resolve(value)
      deferred.promise
    end

    def self.reject(reason)
      deferred = new_deferred
      deferred.reject(reason)
      deferred.promise
    end

    def self.execute(&block)
      deferred = new_deferred
      EXECUTOR.submit do
        begin
          deferred.resolve block.call
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
        callback, arg = if fulfilled?
                          [ on_fulfilled, value ]
                        else
                          [ on_rejected, reason ]
                        end

        begin
          deferred.resolve(callback.call arg)
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
