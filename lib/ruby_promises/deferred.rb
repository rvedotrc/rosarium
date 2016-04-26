module MyConcurrent

  class Deferred

    def initialize(promise, resolver, rejecter)
      @promise = promise
      @resolver = resolver
      @rejecter = rejecter
    end

    def promise
      @promise
    end

    def resolve(value)
      @resolver.call(value)
    end

    def reject(reason)
      @rejecter.call(reason)
    end

  end

end
