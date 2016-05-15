# Rosarium

A library for implementing Promises - or something like them - in ruby.

# Why?

Because I keep hitting bugs and annoying inflexibilities in `concurrent-ruby`,
whereas I really enjoy the stability and flexibility of JavaScript's "Q"
library (<https://github.com/kriskowal/q/wiki/API-Reference>).

I'm not expecting anyone but me to use this code at this time.  But you're
welcome to do so, if you like.

# Example

```
  require 'rosarium'
```

## Static methods for creating promises:

```
  # Immediately ready for async execution:
  promise = Rosarium::Promise.execute { ... }

  # Immediately fulfilled:
  promise = Rosarium::Promise.resolve(anything_except_a_promise)

  # Immediately rejected:
  promise = Rosarium::Promise.reject(an_exception)

  # The same promise (returns its argument)
  a_promise = Rosarium::Promise.resolve(a_promise)

  # Once all promises in the list are fulfilled, then fulfill with a list of
  # their values.  If any promise in the list is rejected, then reject with
  # the same reason:
  promise = Rosarium::Promise.all([ promise1, promise2, ... ])

  # Wait for all the promises in the list to become settled (fulfilled or
  # rejected); then fulfill with the list of promises.
  promise = Rosarium::Promise.all_settled([ promise1, promise2, ... ])
```

## Deferreds

```
  # Create a "deferred":
  deferred = Rosarium::Promise.defer
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
  # One of: :pending, :fulfilled, :rejected.
  promise.state

  # Equivalent to "state == :fulfilled"
  promise.fulfilled?

  # Equivalent to "state == :rejected"
  promise.rejected?

  # Wait for the promise to be settled, then return its value (if fulfilled -
  # note the value may be nil), or nil (if rejected).
  promise.value

  # Wait for the promise to be settled, then return its reason (if rejected),
  # or nil (if fulfilled).
  promise.reason

  # Wait for the promise to be settled, then return its value (if fulfilled),
  # or raise with the rejection reason (if rejected).
  promise.value!

  # A hash describing the state of the promise.  Always includes :state key;
  # may include :value or :reason.
  promise.inspect
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

# Miscellany

Promise code (every time a ruby block appears in the above examples) is run
via a fixed-size thread pool, currently set to 10 threads.  Execution order is
not defined.

