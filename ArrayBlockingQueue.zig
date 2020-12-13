const std = @import("std");

const Condition = @import("./Condition.zig").Condition;


pub fn ArrayBlockingQueue(comptime T: type) type {
    return struct {
        const Self = @This();
        const Fifo = std.fifo.LinearFifo(T, .Dynamic);
    
        capacity: i32 = 0,
        count: i32 = 0,
        queue: Fifo,
        lock: std.Mutex,
        notFull: Condition,
        notEmpty: Condition,
        
        pub fn init(allocator: *std.mem.Allocator, capacity: anytype) Self {
            var self: Self = undefined;
            self.count = 0;
            self.capacity = @as(i32, capacity);
            self.queue = Fifo.init(allocator);
            self.queue.ensureCapacity(capacity) catch unreachable;
            self.lock = std.Mutex{};
            self.notEmpty = Condition{.mutex=null};
            self.notFull = Condition{.mutex=null};

            return self;
        }
        
        pub fn deinit(self: *Self) void {
            self.queue.deinit();
            self.count = 0;
            self.capacity = 0;
        }
        
        pub fn post_init(self: *Self) void {
            if(self.notEmpty.mutex == null)
                self.notEmpty.mutex = &self.lock;
            if(self.notFull.mutex == null)
                self.notFull.mutex = &self.lock;
        }

        pub fn put(self: *Self, item: T) void {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            
            while(self.count == self.capacity){
                self.notFull.wait();
            }
            self.queue.writeItem(item) catch unreachable;
            const count = self.count;
            self.count = self.count + 1;
            if(count == 0)
                self.notEmpty.signalAll();
        }

        pub fn offer(self: *Self, item: T) bool {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            
            if(self.count == self.capacity){
                return false;
            }
            self.queue.writeItem(item) catch unreachable;
            const count = self.count;
            self.count = self.count + 1;
            if(count == 0)
                self.notEmpty.signalAll();
            return true;
        } 

        pub fn timedOffer(self: *Self, item: T, timeout: u64,) bool {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            var t = @intCast(i64, timeout);
            while(self.count == self.capacity){
                if(t <= 0) {
                    return false;
                }
                t = self.notFull.timedWait(@intCast(u64, t));
            }
            
            self.queue.writeItem(item) catch unreachable;
            const prev = self.count;
            self.count += 1;
            if(prev == 0){
                self.notEmpty.signalAll();
            }
            return true;
        }

        pub fn take(self: *Self) T {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            while(self.count == 0){
                self.notEmpty.wait();
            }
            const ret = self.queue.readItem().?;
            const count = self.count;
            self.count = self.count - 1;
            if(count == self.capacity)
                self.notFull.signalAll();
            return ret;
        }
        
        pub fn takeMany(self: *Self, dst: []T) []T {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            while(self.count == 0){
                self.notEmpty.wait();
            }
            const num = self.queue.read(dst);
            const count = self.count;
            std.testing.expect(count-@intCast(i32, num) >= 0);
            self.count = self.count - @intCast(i32, num);
            if(count == self.capacity)
                self.notFull.signalAll();
            return dst[0..num];
        }
        
        pub fn pollMany(self: *Self, dst: []T) []T {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            if(self.count == 0){
                return dst[0..0];
            }
            
            const num = self.queue.read(dst);
            const count = self.count;
            std.testing.expect(count-@intCast(i32, num) >= 0);
            self.count = self.count - @intCast(i32, num);
            if(count == self.capacity)
                self.notFull.signalAll();
            return dst[0..num];
        }
        
        pub fn poll(self: *Self) ?T {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            if(self.count == 0){
                return null;
            }
            
            const ret = self.queue.readItem().?;
            const count = self.count;
            self.count = self.count - 1;
            if(count == self.capacity)
                self.notFull.signalAll();
            return ret;
        }
        
        pub fn timedPoll(self: *Self, timeout: u64) ?T {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            var t = @intCast(i64, timeout);
            while(self.count == 0){
                if(t <= 0) {
                    return null;
                }
                t = self.notEmpty.timedWait(@intCast(u64, t));
            }
            const ret = self.queue.readItem().?;
            const prev = self.count;
            self.count -= 1;
            if(prev == self.capacity){
                self.notFull.signalAll();
            }
            return ret;
        }
        
        pub fn peek(self: *Self) ?T {
            const lock = self.lock.acquire();
            defer lock.release();
            self.post_init();
            if(self.count == 0){
                return null;
            }
            
            const ret = self.queue.peekItem(0);
            return ret;
        }
    };
}
