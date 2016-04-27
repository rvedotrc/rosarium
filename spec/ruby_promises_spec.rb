require "ruby_promises"

describe MyConcurrent::Promise do

  def check_pending(promise)
    expect(promise.state).to eq(:pending)
    expect(promise).not_to be_fulfilled
    expect(promise).not_to be_rejected
    # expect(promise.value).to be_nil # should block
    # expect(promise.reason).to be_nil # should block
  end

  def check_resolving(promise)
    expect(promise.state).to eq(:resolving)
    expect(promise).not_to be_fulfilled
    expect(promise).not_to be_rejected
    # expect(promise.value).to be_nil # should block
    # expect(promise.reason).to be_nil # should block
  end

  def check_fulfilled(promise, value)
    expect(promise.state).to eq(:fulfilled)
    expect(promise).to be_fulfilled
    expect(promise).not_to be_rejected
    expect(promise.value).to eq(value)
    expect(promise.reason).to be_nil
  end

  def check_rejected(promise, e)
    expect(promise.state).to eq(:rejected)
    expect(promise).not_to be_fulfilled
    expect(promise).to be_rejected
    expect(promise.value).to eq(nil)
    expect(promise.reason).to eq(e)
  end

  def an_error(message = "bang")
    RuntimeError.new(message)
  end

  # Creating instantly-resolved promises

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

  # Creating deferreds

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

  it "can be resolved with a later-fulfilled promise" do
    d1 = MyConcurrent::Promise.defer
    d2 = MyConcurrent::Promise.defer
    d1.resolve(d2.promise)
    check_resolving d1.promise
    d2.resolve 7
    check_fulfilled d1.promise, 7
  end

  it "can be resolved with a later-rejected promise" do
    d1 = MyConcurrent::Promise.defer
    d2 = MyConcurrent::Promise.defer
    d1.resolve(d2.promise)
    check_resolving d1.promise
    e = an_error
    d2.reject e
    check_rejected d1.promise, e
  end

  # TODO:
  # fulfill-with-promise (then? deferred?)
  # reject-with-promise (then? deferred?)
  # .all
  # .allSettled
  # .spread
  # blocking .value, .value!, .reason

end
