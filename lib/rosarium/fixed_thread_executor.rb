module Rosarium

  class FixedThreadExecutor

    def initialize(max = 1)
      @max = max
      @mutex = Mutex.new
      @waiting = []
      @executing = 0
      @threads = []
    end

    def submit(&block)
      @mutex.synchronize do
        @waiting << block
        if @executing < @max
          @executing = @executing + 1
          t = Thread.new { execute_and_count_down }
          @threads.push t
        end
      end
    end

    def discard
      @mutex.synchronize { @waiting.clear }
    end

    def wait_until_idle
      loop do
        t = @mutex.synchronize { @threads.shift }
        t or break
        t.join
      end
    end

    private

    def execute_and_count_down
      begin
        execute
      ensure
        @mutex.synchronize do
          @executing = @executing - 1
        end
      end
    end

    def execute
      while true
        block = @mutex.synchronize { @waiting.shift }
        block or break
        begin
          block.call
        rescue Exception => e
        end
      end
    end

  end

end
