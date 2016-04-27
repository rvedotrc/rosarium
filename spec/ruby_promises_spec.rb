require "ruby_promises"
require_relative "./promise_test_helper"

describe MyConcurrent::Promise do

  include PromiseTestHelper

  # Creating immediately-executable promises

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

  # Chaining promises

  it "supports simple 'then'" do
    deferred = MyConcurrent::Promise.defer
    chained = deferred.promise.then {|arg| arg * 2}
    check_pending chained
    deferred.resolve 7
    sleep 0.1
    check_fulfilled chained, 14
  end

  it "rejects if 'then' raises an error" do
    e = an_error
    deferred = MyConcurrent::Promise.defer
    chained = deferred.promise.then { raise e }
    check_pending chained
    deferred.resolve 7
    sleep 0.1
    check_rejected chained, e
  end

  it "rejects if the parent rejects" do
    e = an_error
    deferred = MyConcurrent::Promise.defer
    then_called = false
    chained = deferred.promise.then { then_called = true }
    check_pending chained
    deferred.reject e
    check_rejected chained, e
    expect(then_called).to be_falsy
  end

  it "supports then(on_rejected)" do
    e = an_error
    e2 = an_error("another")
    deferred = MyConcurrent::Promise.defer
    got_args = nil
    chained = deferred.promise.then(Proc.new {|*args| got_args = args; raise e2 }) { raise "should never be called" }
    deferred.reject e
    check_rejected chained, e2
    expect(got_args).to eq([e])
  end

  it "on_rejected can cause fulfilled" do
    deferred = MyConcurrent::Promise.defer
    chained = deferred.promise.then(Proc.new {7}) { raise "should never be called" }
    deferred.reject an_error
    check_fulfilled chained, 7
  end

  it "supports rescue/catch/on_error" do
    %i[ rescue catch on_error ].each do |method|
      deferred = MyConcurrent::Promise.defer
      chained = deferred.promise.send(method) { 7 }
      deferred.reject an_error
      check_fulfilled chained, 7
    end
  end

  # TODO:
  # fulfill-with-promise (then? deferred?)
  # reject-with-promise (then? deferred?)
  # .all
  # .allSettled
  # .spread
  # blocking .value, .value!, .reason

end
