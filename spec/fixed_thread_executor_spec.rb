require "rosarium"

describe Rosarium::FixedThreadExecutor do

  it "runs a job" do
    ex = Rosarium::FixedThreadExecutor.new(1)
    done = false
    ex.submit { done = true }
    ex.wait_until_idle
    expect(done).to be_truthy
  end

  it "discards exceptions" do
    ex = Rosarium::FixedThreadExecutor.new(1)
    done = false
    ex.submit { raise "bang" }
    ex.submit { done = true }
    ex.wait_until_idle
    expect(done).to be_truthy
  end

  it "runs jobs concurrently" do
    ex = Rosarium::FixedThreadExecutor.new(3)
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

