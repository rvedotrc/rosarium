require "ruby_promises"
require_relative "./promise_test_helper"

describe "instantly-resolved promises" do

  include PromiseTestHelper

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

end
