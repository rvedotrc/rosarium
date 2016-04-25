require "ruby_promises"

describe MyConcurrent::Promise do

  it "creates a pending promise" do
    promise = MyConcurrent::Promise.new
    expect(promise.state).to eq(:pending)
    expect(promise).not_to be_fulfilled
    expect(promise).not_to be_rejected
    # expect(promise.value).to eq(nil)
    # expect(promise.reason).to eq(nil)
  end

  it "creates a fulfilled promise" do
    promise = MyConcurrent::Promise.fulfill(7)
    expect(promise.state).to eq(:fulfilled)
    expect(promise).to be_fulfilled
    expect(promise).not_to be_rejected
    expect(promise.value).to eq(7)
    expect(promise.reason).to eq(nil)
  end

  it "creates a rejected promise" do
    e = StandardError.new
    promise = MyConcurrent::Promise.reject(e)
    expect(promise.state).to eq(:rejected)
    expect(promise).not_to be_fulfilled
    expect(promise).to be_rejected
    expect(promise.value).to eq(nil)
    expect(promise.reason).to eq(e)
  end

end
