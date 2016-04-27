# ruby-promises

A library for implementing Promises - or something like them - in ruby.

# Why?

Because I keep hitting bugs and annoying inflexibilities in `concurrent-ruby`,
whereas I really enjoy the stability and flexibility of JavaScript's "Q"
(<https://github.com/kriskowal/q/wiki/API-Reference>).

# Example

```
  require 'ruby-promises'
```

## Static methods for creating promises:

```
  # Immediately ready for async execution:
  promise = MyConcurrent::Promise.execute { ... }

  # Immediately fulfilled:
  promise = MyConcurrent::Promise.resolve(anything_except_a_promise)

  # Immediately rejected:
  promise = MyConcurrent::Promise.reject(an_exception)

  # The same promise (returns its argument)
  a_promise = MyConcurrent::Promise.resolve(a_promise)

  # Once all promises in the list are fulfilled, then fulfill with a list of
  # their values.  If any promise in the list is rejected, then reject with
  # the same reason:
  promise = MyConcurrent::Promise.all?([ promise1, promise2, ... ])

  # Wait for all the promises in the list to become settled (fulfilled or
  # rejected); then fulfill with the list of promises.
  promise = MyConcurrent::Promise.all_settled([ promise1, promise2, ... ])
```

## Deferreds

```
  # Create a "deferred":
  deferred = MyConcurrent::Promise.defer
  promise = deferred.promise
```

then later, use the "deferred" to fulfill or reject the promise:

```
  # Fulfill:
  deferred.resolve(anything_except_a_promise)

  # Reject:
  deferred.reject(an_exception)

  # Fulfill or reject, once the other promise is fulfilled / rejected:
  deferred.resolve(other_promise)
```

## Methods of promises:

```
  # One of: :pending, :resolving, :fulfilled, :rejected.
  promise.state

  # Wait for the promise to be settled, then return its value (if fulfilled -
  # note the value may be nil), or nil (if rejected).
  promise.value

  # Wait for the promise to be settled, then return its reason (if rejected),
  # or nil (if fulfilled).
  promise.reason

  # true iff state == :fulfilled
  promise.fulfilled?

  # true iff state == :rejected
  promise.rejected?

  # Wait for the promise to be settled, then return its value (if fulfilled),
  # or raise with the rejection reason (if rejected).
  promise.value!

  # Wait for the promise to be settled
  promise.wait
```

Chaining promises together:

```
  # Handling promise1 fulfillment:
  promise2 = promise1.then { |promise1_value| ... }

  # Four different ways of handling promise1 rejection:
  promise2 = promise1.then(Proc.new { |promise1_reason| ... })
  promise2 = promise1.rescue { |promise1_reason| ... }
  promise2 = promise1.catch { |promise1_reason| ... }
  promise2 = promise1.on_error { |promise1_reason| ... }

  # Handle both fulfillment and rejection:
  promise2 = promise1.then(Proc.new { |promise1_reason| ... }) { |promise1_value| ... }
```

