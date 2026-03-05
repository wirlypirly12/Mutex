# Mutex

Roblox mutex library with an O(1) linked list queue and no busy waiting.

## Features

- **FIFO queuing** - threads are resumed in the order they called `lock()`, using an O(1) linked list
- **Deadlock detection** - errors immediately if a coroutine tries to lock a mutex it already owns
- **Ownership enforcement** - only the thread that locked the mutex can unlock it
- **Non blocking variant** - `tryLock()` for contexts where yielding isn't possible
- **Safe deferral** - uses `task.defer` to resume waiting threads without inline reentrancy

## Installation

Copy `Mutex.luau` into your environment and require it:

```lua
local Mutex = require(Path.To.Mutex)
```

## Usage

### Basic locking

```lua
local m = Mutex()

local thread = coroutine.wrap(function()
    m:lock()
    -- critical section
    m:unlock()
end)
```

### Using `run()` for automatic lock/unlock

```lua
m:run(function()
    -- automatically locked before and unlocked after
    -- even if an error is thrown
end)
```

### Non-yieldable contexts

```lua
if m:tryLock() then
    -- critical section
    m:unlock()
else
    -- mutex was already locked, handle accordingly
end
```

## API

### `Mutex.new()`
Creates and returns a new mutex instance.

### `mutex:lock()`
Acquires the mutex. If it is already locked, the calling coroutine yields and is queued until the mutex becomes available. Errors if the calling thread is not yieldable, or if the calling thread already owns the mutex.

### `mutex:tryLock() -> boolean`
Attempts to acquire the mutex without yielding. Returns `true` if successful, `false` if the mutex is already locked. Safe to call in a non yieldable context.

### `mutex:unlock()`
Releases the mutex. If threads are waiting, the next one in queue is scheduled via `task.defer`. Errors if the mutex is not locked or if the calling thread is not the owner.

### `mutex:run(callback, ...) -> any`
Locks the mutex, calls `callback(...)` inside `pcall`, then unlocks. Raises any error after unlocking. Returns the callback's return value on success.

## License

MIT License - Copyright (c) wirlypirly12
