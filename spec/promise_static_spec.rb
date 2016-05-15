require "rosarium"
require_relative "./promise_test_helper"

describe "instantly-resolved promises" do

  include PromiseTestHelper

  it "returns the same promise" do
    d = Rosarium::Promise.defer
    t = Rosarium::Promise.resolve d.promise
    expect(t).to eq(d.promise)
  end

  it "creates a fulfilled promise" do
    t = Rosarium::Promise.resolve 7
    check_fulfilled t, 7
    expect(t).not_to respond_to(:fulfill)
    expect(t).not_to respond_to(:reject)
  end

  it "creates a rejected promise" do
    e = an_error
    t = Rosarium::Promise.reject an_error
    check_rejected t, an_error
    expect(t).not_to respond_to(:fulfill)
    expect(t).not_to respond_to(:reject)
  end

  it "creates an immediately-executable promise" do
    promise = Rosarium::Promise.execute do
      sleep 0.1 ; 7
    end
    check_pending promise
    sleep 0.2
    check_fulfilled promise, 7
  end

  it "catches errors from the executed block and rejects" do
    e = RuntimeError.new("bang")
    promise = Rosarium::Promise.execute do
      sleep 0.1 ; raise e
    end
    check_pending promise
    sleep 0.2
    check_rejected promise, e
  end

  it "supports all_settled (empty)" do
    promise = Rosarium::Promise.all_settled []
    check_fulfilled promise, []
  end

  it "supports all_settled (non-empty)" do
    d1 = Rosarium::Promise.defer
    d2 = Rosarium::Promise.defer
    promise = Rosarium::Promise.all_settled [d1.promise, d2.promise]
    check_pending promise

    d1.resolve 7
    check_pending promise

    e = an_error
    d2.reject e
    promise.value
    check_fulfilled promise, [ d1.promise, d2.promise ]
  end

  it "supports all (empty)" do
    promise = Rosarium::Promise.all []
    check_fulfilled promise, []
  end

  it "supports all (reject)" do
    d1 = Rosarium::Promise.defer
    d2 = Rosarium::Promise.defer
    d3 = Rosarium::Promise.defer
    promise = Rosarium::Promise.all [d1.promise, d2.promise, d3.promise]
    check_pending promise

    d1.resolve 7
    check_pending promise

    e = an_error
    d3.reject e
    promise.value
    check_rejected promise, e
  end

  it "supports all (fulfill)" do
    d1 = Rosarium::Promise.defer
    d2 = Rosarium::Promise.defer
    promise = Rosarium::Promise.all [d1.promise, d2.promise]
    check_pending promise

    d1.resolve 7
    check_pending promise

    d2.resolve 8
    promise.value
    check_fulfilled promise, [7,8]
  end

end
