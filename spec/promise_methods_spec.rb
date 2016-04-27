require "rosarium"
require_relative "./promise_test_helper"

describe Rosarium::Promise do

  include PromiseTestHelper

  # Chaining promises

  it "supports simple 'then'" do
    deferred = Rosarium::Promise.defer
    chained = deferred.promise.then {|arg| arg * 2}
    check_pending chained
    deferred.resolve 7
    sleep 0.1
    check_fulfilled chained, 14
  end

  it "rejects if 'then' raises an error" do
    e = an_error
    deferred = Rosarium::Promise.defer
    chained = deferred.promise.then { raise e }
    check_pending chained
    deferred.resolve 7
    sleep 0.1
    check_rejected chained, e
  end

  it "rejects if the parent rejects" do
    e = an_error
    deferred = Rosarium::Promise.defer
    then_called = false
    chained = deferred.promise.then { then_called = true }
    check_pending chained
    deferred.reject e
    chained.wait
    check_rejected chained, e
    expect(then_called).to be_falsy
  end

  it "supports then(on_rejected)" do
    e = an_error
    e2 = an_error("another")
    deferred = Rosarium::Promise.defer
    got_args = nil
    chained = deferred.promise.then(Proc.new {|*args| got_args = args; raise e2 }) { raise "should never be called" }
    deferred.reject e
    chained.wait
    check_rejected chained, e2
    expect(got_args).to eq([e])
  end

  it "on_rejected can cause fulfilled" do
    deferred = Rosarium::Promise.defer
    chained = deferred.promise.then(Proc.new {7}) { raise "should never be called" }
    deferred.reject an_error
    chained.wait
    check_fulfilled chained, 7
  end

  it "supports rescue/catch/on_error" do
    %i[ rescue catch on_error ].each do |method|
      deferred = Rosarium::Promise.defer
      chained = deferred.promise.send(method) { 7 }
      deferred.reject an_error
      chained.wait
      check_fulfilled chained, 7
    end
  end

end
