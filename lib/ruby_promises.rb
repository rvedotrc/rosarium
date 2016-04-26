require_relative 'ruby_promises/fixed_thread_executor'
require_relative 'ruby_promises/simple_promise'
require_relative 'ruby_promises/deferred'
require_relative 'ruby_promises/promise'

module MyConcurrent

  EXECUTOR = FixedThreadExecutor.new(10)

end
