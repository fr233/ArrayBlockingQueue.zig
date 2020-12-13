# ArrayBlockingQueue.zig
ArrayBlockingQueue for zig lang

# API
* `ArrayBlockingQueue(comptime T: type) type`
generic type.

* `init(allocator: *std.mem.Allocator, capacity: anytype) Self`
construct an ArrayBlockingQueue object.

* `put(self: *Self, item: T) void`
enqueue item, waiting for space to become available if the queue is full.

* `take(self: *Self) void`
dequeue an item, waiting if necessary until an element becomes available.

* `offer(self: *Self, item: T) bool`
enqueue item, returning true upon success and false if no space is currently available.

* `timedOffer(self: *Self, item: T, timeout: u64,) bool`
enqueue item, returning true upon success and false if timed out.

* `takeMany(self: *Self, dst: []T) []T`
dequeue at most dst.len items, waiting if necessary until at least an element becomes available.

* `poll(self: *Self) ?T`
dequeue an item, return null if this queue is empty.

* `pollMany(self: *Self, dst: []T) []T`
dequeue at most dst.len items, return null if this queue is empty.

* `timedPoll(self: *Self, timeout: u64) ?T`
dequeue an item, return null if timed out.

* `peek(self: *Self) ?T`
retrieves, but does not dequeue the head of queue, returns null if this queue is empty.


## Notes
this queue depends on [Condition.zig](https://github.com/fr233/Condition.zig)

