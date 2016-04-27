require "ruby_promises"
require_relative "./promise_test_helper"

describe "instantly-resolved promises" do

  include PromiseTestHelper

  it "returns the same promise" do
    d = MyConcurrent::Promise.defer
    t = MyConcurrent::Promise.resolve d.promise
    expect(t).to eq(d.promise)
  end

  it "creates a fulfilled promise" do
    t = MyConcurrent::Promise.resolve 7
    check_fulfilled t, 7
    expect(t).not_to respond_to(:fulfill)
    expect(t).not_to respond_to(:reject)
  end

  it "creates a rejected promise" do
    e = an_error
    t = MyConcurrent::Promise.reject an_error
    check_rejected t, an_error
    expect(t).not_to respond_to(:fulfill)
    expect(t).not_to respond_to(:reject)
  end

  it "creates an immediately-executable promise" do
    promise = MyConcurrent::Promise.execute do
      sleep 0.1 ; 7
    end
    check_pending promise
    sleep 0.2
    check_fulfilled promise, 7
  end

  it "catches errors from the executed block and rejects" do
    e = RuntimeError.new("bang")
    promise = MyConcurrent::Promise.execute do
      sleep 0.1 ; raise e
    end
    check_pending promise
    sleep 0.2
    check_rejected promise, e
  end

end
