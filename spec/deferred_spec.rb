require "ruby_promises"
require_relative "./promise_test_helper"

describe "deferred promises" do

  include PromiseTestHelper

  it "creates a pending promise" do
    deferred = MyConcurrent::Promise.defer
    check_pending deferred.promise
  end

  it "deferred can be fulfilled only once" do
    deferred = MyConcurrent::Promise.defer
    check_pending deferred.promise
    deferred.resolve 7
    check_fulfilled deferred.promise, 7
    deferred.resolve 8
    check_fulfilled deferred.promise, 7
    deferred.reject an_error
    check_fulfilled deferred.promise, 7
  end

  it "deferred can be rejected only once" do
    e = an_error
    deferred = MyConcurrent::Promise.defer
    check_pending deferred.promise
    deferred.reject e
    check_rejected deferred.promise, e
    deferred.reject an_error("again")
    check_rejected deferred.promise, e
    deferred.resolve 9
    check_rejected deferred.promise, e
  end

  it "can only be rejected with an exception" do
    deferred = MyConcurrent::Promise.defer
    check_pending deferred.promise
    expect { deferred.reject "123" }.to raise_error /reason must be an Exception/
    check_pending deferred.promise
  end

  it "can be resolved with an already-fulfilled promise" do
    d1 = MyConcurrent::Promise.defer
    d2 = MyConcurrent::Promise.defer
    d2.resolve 7
    d1.resolve(d2.promise)
    check_fulfilled d1.promise, 7
  end

  it "can be resolved with an already-rejected promise" do
    d1 = MyConcurrent::Promise.defer
    d2 = MyConcurrent::Promise.defer
    e = an_error
    d2.reject e
    d1.resolve(d2.promise)
    check_rejected d1.promise, e
  end

  it "can be resolved with a later-fulfilled promise" do
    d1 = MyConcurrent::Promise.defer
    d2 = MyConcurrent::Promise.defer
    d1.resolve(d2.promise)
    check_resolving d1.promise
    d2.resolve 7
    d1.promise.wait
    check_fulfilled d1.promise, 7
  end

  it "can be resolved with a later-rejected promise" do
    d1 = MyConcurrent::Promise.defer
    d2 = MyConcurrent::Promise.defer
    d1.resolve(d2.promise)
    check_resolving d1.promise
    e = an_error
    d2.reject e
    d1.promise.wait
    check_rejected d1.promise, e
  end

  it "waits for a value (fulfilled)" do
    d = MyConcurrent::Promise.defer
    check_pending d.promise
    Thread.new { sleep 0.1; d.resolve 7 }
    v = d.promise.value
    expect(v).to eq(7)
  end

  it "waits for a value (rejected)" do
    d = MyConcurrent::Promise.defer
    check_pending d.promise
    Thread.new { sleep 0.1; d.reject an_error }
    v = d.promise.value
    expect(v).to eq(nil)
    expect(d.promise).to be_rejected
  end

  it "waits for a reason (fulfilled)" do
    d = MyConcurrent::Promise.defer
    check_pending d.promise
    Thread.new { sleep 0.1; d.resolve 7 }
    r = d.promise.reason
    expect(r).to eq(nil)
    expect(d.promise).to be_fulfilled
  end

  it "waits for a reason (rejected)" do
    d = MyConcurrent::Promise.defer
    check_pending d.promise
    e = an_error
    Thread.new { sleep 0.1; d.reject e }
    r = d.promise.reason
    expect(r).to eq(e)
  end

  it "waits for a value! (fulfilled)" do
    d = MyConcurrent::Promise.defer
    check_pending d.promise
    Thread.new { sleep 0.1; d.resolve 7 }
    v = d.promise.value!
    expect(v).to eq(7)
  end

  it "waits for a value! (rejected)" do
    d = MyConcurrent::Promise.defer
    check_pending d.promise
    e = an_error
    Thread.new { sleep 0.1; d.reject e }
    expect {
      d.promise.value!
    }.to raise_error(e)
  end

end
