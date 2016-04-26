require "ruby_promises"

describe MyConcurrent::Promise do

  def check_pending(promise)
    expect(promise.state).to eq(:pending)
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

  # Creating instantly-resolved promises

  it "creates a fulfilled promise" do
    t = MyConcurrent::Promise.fulfill 7
    check_fulfilled t, 7
    expect(t).not_to respond_to(:fulfill)
    expect(t).not_to respond_to(:reject)
  end

  it "creates a rejected promise" do
    t = MyConcurrent::Promise.reject 7
    check_rejected t, 7
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
    deferred.fulfill 7
    check_fulfilled deferred.promise, 7
    deferred.fulfill 8
    check_fulfilled deferred.promise, 7
    deferred.reject 9
    check_fulfilled deferred.promise, 7
  end

  it "deferred can be rejected only once" do
    deferred = MyConcurrent::Promise.defer
    check_pending deferred.promise
    deferred.reject 7
    check_rejected deferred.promise, 7
    deferred.reject 8
    check_rejected deferred.promise, 7
    deferred.fulfill 9
    check_rejected deferred.promise, 7
  end

end
