require "ruby_promises"

describe MyConcurrent::FixedThreadExecutor do

  it "runs a job" do
    ex = MyConcurrent::FixedThreadExecutor.new(1)
    done = false
    ex.submit { done = true }
    ex.wait_until_idle
    expect(done).to be_truthy
  end

  it "discards exceptions" do
    ex = MyConcurrent::FixedThreadExecutor.new(1)
    done = false
    ex.submit { raise "bang" }
    ex.submit { done = true }
    ex.wait_until_idle
    expect(done).to be_truthy
  end

  it "runs jobs concurrently" do
    ex = MyConcurrent::FixedThreadExecutor.new(3)
    m = Mutex.new
    done = []
    3.times do
      ex.submit do
        m.synchronize { done << "s" }
        sleep 0.1
        m.synchronize { done << "e" }
      end
    end
    ex.wait_until_idle
    expect(done).to eq(%w[ s s s e e e ])
  end

end

