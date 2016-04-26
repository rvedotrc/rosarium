module MyConcurrent

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

end
