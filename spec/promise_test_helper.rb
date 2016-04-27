module PromiseTestHelper

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

end
