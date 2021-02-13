# frozen_string_literal: true

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
          @executing += 1
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
      execute
    ensure
      @mutex.synchronize do
        @executing -= 1
      end
    end

    def execute
      loop do
        block = @mutex.synchronize { @waiting.shift }
        block or break
        begin
          block.call
        rescue Exception
        end
      end
    end

  end
end
