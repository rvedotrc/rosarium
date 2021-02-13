# frozen_string_literal: true

module Rosarium
  class Deferred

    def initialize(promise, resolver, rejecter)
      @promise = promise
      @resolver = resolver
      @rejecter = rejecter
    end

    attr_reader :promise

    def resolve(value)
      @resolver.call(value)
    end

    def reject(reason)
      @rejecter.call(reason)
    end

  end
end
