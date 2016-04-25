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

  it "creates a pending promise" do
    promise = MyConcurrent::Promise.new
    check_pending promise
  end

  it "creates and then fulfills a promise" do
    promise = MyConcurrent::Promise.new
    check_pending promise
    promise.fulfill 7
    check_fulfilled promise, 7
  end

  it "creates and then rejects a promise" do
    e = StandardError.new
    promise = MyConcurrent::Promise.new
    check_pending promise
    promise.reject e
    check_rejected promise, e
  end

  it "creates a fulfilled promise" do
    promise = MyConcurrent::Promise.fulfill(7)
    check_fulfilled promise, 7
  end

  it "creates a rejected promise" do
    e = StandardError.new
    promise = MyConcurrent::Promise.reject(e)
    check_rejected promise, e
  end

end
