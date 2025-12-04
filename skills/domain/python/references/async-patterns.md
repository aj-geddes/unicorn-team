# Async Patterns and Best Practices

Comprehensive guide to Python's asyncio ecosystem.

## Fundamentals

```python
import asyncio
from typing import AsyncIterator, Awaitable

# Basic async function
async def fetch_data(url: str) -> dict:
    """Async function (coroutine)."""
    await asyncio.sleep(1)  # Simulated I/O
    return {"url": url, "status": "ok"}

# Running async code
def main():
    # Run single coroutine
    result = asyncio.run(fetch_data("https://api.example.com"))

    # Run with custom event loop
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        result = loop.run_until_complete(fetch_data("url"))
    finally:
        loop.close()

# Running from async context
async def async_main():
    result = await fetch_data("url")
    return result

# Python 3.11+ task groups
async def parallel_fetches(urls: list[str]) -> list[dict]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_data(url)) for url in urls]
    # All tasks complete here, or exception raised
    return [task.result() for task in tasks]
```

## Gathering and Concurrency Control

```python
# gather for parallel execution
async def fetch_all_basic(urls: list[str]) -> list[dict]:
    """Run all coroutines concurrently."""
    results = await asyncio.gather(
        *[fetch_data(url) for url in urls]
    )
    return results

# gather with exception handling
async def fetch_all_safe(urls: list[str]) -> list[dict | Exception]:
    """Continue on exceptions."""
    results = await asyncio.gather(
        *[fetch_data(url) for url in urls],
        return_exceptions=True  # Returns exceptions instead of raising
    )
    return results

# as_completed for processing as they finish
async def fetch_process_as_done(urls: list[str]) -> None:
    """Process results as soon as available."""
    coros = [fetch_data(url) for url in urls]
    for coro in asyncio.as_completed(coros):
        result = await coro
        print(f"Got result: {result}")

# Semaphore for rate limiting
async def fetch_with_limit(urls: list[str], max_concurrent: int = 5) -> list[dict]:
    """Limit concurrent requests."""
    semaphore = asyncio.Semaphore(max_concurrent)

    async def fetch_limited(url: str) -> dict:
        async with semaphore:
            return await fetch_data(url)

    return await asyncio.gather(*[fetch_limited(url) for url in urls])

# Queue for producer-consumer pattern
async def producer_consumer(items: list[str]) -> None:
    """Producer-consumer with queue."""
    queue: asyncio.Queue[str] = asyncio.Queue()

    async def producer():
        for item in items:
            await queue.put(item)
            await asyncio.sleep(0.1)
        await queue.put(None)  # Sentinel

    async def consumer():
        while True:
            item = await queue.get()
            if item is None:
                break
            print(f"Processing {item}")
            await asyncio.sleep(0.2)

    await asyncio.gather(producer(), consumer())

# Priority queue
async def priority_processor() -> None:
    """Process tasks by priority."""
    queue: asyncio.PriorityQueue[tuple[int, str]] = asyncio.PriorityQueue()

    await queue.put((1, "high priority"))
    await queue.put((5, "low priority"))
    await queue.put((3, "medium priority"))

    while not queue.empty():
        priority, task = await queue.get()
        print(f"Processing priority {priority}: {task}")
```

## Task Management

```python
# Create and manage tasks
async def task_management():
    # Create task (starts immediately)
    task = asyncio.create_task(fetch_data("url"))

    # Do other work
    await asyncio.sleep(0.5)

    # Wait for task
    result = await task

# Task with name (for debugging)
async def named_tasks():
    task1 = asyncio.create_task(fetch_data("url1"), name="fetch1")
    task2 = asyncio.create_task(fetch_data("url2"), name="fetch2")

    # Get all tasks
    tasks = asyncio.all_tasks()
    for task in tasks:
        print(f"Task: {task.get_name()}")

    await asyncio.gather(task1, task2)

# Task cancellation
async def cancellable_operation():
    task = asyncio.create_task(long_running_task())

    await asyncio.sleep(1)
    task.cancel()  # Request cancellation

    try:
        await task
    except asyncio.CancelledError:
        print("Task was cancelled")

async def long_running_task():
    try:
        for i in range(100):
            await asyncio.sleep(0.1)
            print(f"Step {i}")
    except asyncio.CancelledError:
        print("Cleaning up...")
        raise  # Re-raise to complete cancellation

# shield to prevent cancellation
async def critical_section():
    task = asyncio.create_task(important_operation())

    # Protect from cancellation
    try:
        result = await asyncio.shield(task)
    except asyncio.CancelledError:
        # critical_section was cancelled, but task continues
        result = await task  # Wait for it to finish

    return result

# Timeout handling
async def with_timeout(url: str) -> dict:
    try:
        return await asyncio.wait_for(fetch_data(url), timeout=5.0)
    except asyncio.TimeoutError:
        print(f"Request to {url} timed out")
        return {"error": "timeout"}

# Multiple timeouts (3.11+)
async def with_multiple_timeouts():
    async with asyncio.timeout(10):  # Outer timeout
        result1 = await fetch_data("url1")

        async with asyncio.timeout(5):  # Inner timeout
            result2 = await fetch_data("url2")

    return result1, result2
```

## Async Context Managers

```python
from typing import AsyncContextManager

# Simple async context manager
class AsyncResource:
    async def __aenter__(self):
        print("Acquiring resource")
        await asyncio.sleep(0.1)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        print("Releasing resource")
        await asyncio.sleep(0.1)
        return False

async def use_resource():
    async with AsyncResource() as resource:
        print("Using resource")

# Function-based async context manager
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_connection(url: str):
    # Setup
    conn = await connect(url)
    try:
        yield conn
    finally:
        # Cleanup
        await conn.close()

async def use_connection():
    async with managed_connection("db://localhost") as conn:
        await conn.query("SELECT * FROM users")

# Combining multiple async context managers
async def multiple_resources():
    async with AsyncResource() as r1, AsyncResource() as r2:
        print("Using both resources")

# ExitStack for dynamic context managers (3.11+)
from contextlib import AsyncExitStack

async def dynamic_contexts(urls: list[str]):
    async with AsyncExitStack() as stack:
        connections = [
            await stack.enter_async_context(managed_connection(url))
            for url in urls
        ]
        # Use all connections
        results = await asyncio.gather(
            *[conn.query("SELECT 1") for conn in connections]
        )
    # All connections closed here
```

## Async Iterators and Generators

```python
# Async iterator protocol
class AsyncRange:
    def __init__(self, start: int, end: int):
        self.current = start
        self.end = end

    def __aiter__(self):
        return self

    async def __anext__(self):
        if self.current >= self.end:
            raise StopAsyncIteration
        await asyncio.sleep(0.1)  # Simulated async work
        self.current += 1
        return self.current - 1

async def use_async_iterator():
    async for i in AsyncRange(0, 5):
        print(i)

# Async generator (simpler)
async def async_range(start: int, end: int) -> AsyncIterator[int]:
    for i in range(start, end):
        await asyncio.sleep(0.1)
        yield i

async def use_async_generator():
    async for i in async_range(0, 5):
        print(i)

# Streaming data
async def stream_lines(filename: str) -> AsyncIterator[str]:
    """Stream file lines asynchronously."""
    async with aiofiles.open(filename) as f:
        async for line in f:
            yield line.strip()

async def process_file(filename: str):
    async for line in stream_lines(filename):
        print(f"Processing: {line}")

# Async comprehensions
async def fetch_all_comprehension(urls: list[str]) -> list[dict]:
    # Async list comprehension
    results = [await fetch_data(url) for url in urls]  # Sequential!
    return results

async def fetch_all_concurrent(urls: list[str]) -> list[dict]:
    # Create tasks, then gather
    tasks = [asyncio.create_task(fetch_data(url)) for url in urls]
    results = [await task for task in tasks]  # Still sequential await
    return results

async def fetch_all_proper(urls: list[str]) -> list[dict]:
    # Proper concurrent execution
    return await asyncio.gather(*[fetch_data(url) for url in urls])

# Async generator with cleanup
async def monitored_stream() -> AsyncIterator[dict]:
    connection = await connect()
    try:
        while True:
            data = await connection.receive()
            if data is None:
                break
            yield data
    finally:
        await connection.close()
```

## Async with Sync Code

```python
import concurrent.futures
from functools import partial

# Run sync code in thread pool
async def run_sync_in_thread():
    loop = asyncio.get_running_loop()

    # CPU-bound work in executor
    result = await loop.run_in_executor(
        None,  # Default ThreadPoolExecutor
        cpu_bound_function,
        arg1,
        arg2
    )
    return result

# Custom executor
async def with_process_pool():
    loop = asyncio.get_running_loop()

    with concurrent.futures.ProcessPoolExecutor() as pool:
        result = await loop.run_in_executor(
            pool,
            cpu_intensive_task,
            data
        )
    return result

# Wrapper for sync functions
async def to_async(func, *args, **kwargs):
    """Convert sync function to async."""
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(
        None,
        partial(func, *args, **kwargs)
    )

# Run async from sync code (avoid in async context!)
def sync_function():
    result = asyncio.run(async_operation())
    return result

# Sync wrapper with proper loop handling
def run_async_safely(coro):
    """Run async code from sync context."""
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        # No loop running
        return asyncio.run(coro)
    else:
        # Loop already running (nested)
        raise RuntimeError("Cannot run asyncio.run() within async context")
```

## Synchronization Primitives

```python
# Lock for mutual exclusion
shared_resource = 0
lock = asyncio.Lock()

async def increment():
    global shared_resource
    async with lock:
        # Critical section
        temp = shared_resource
        await asyncio.sleep(0.01)  # Simulated work
        shared_resource = temp + 1

# Event for signaling
event = asyncio.Event()

async def waiter():
    print("Waiting for event")
    await event.wait()  # Blocks until set
    print("Event received")

async def setter():
    await asyncio.sleep(1)
    print("Setting event")
    event.set()

# Condition for complex coordination
condition = asyncio.Condition()
items: list[str] = []

async def consumer():
    async with condition:
        await condition.wait_for(lambda: len(items) > 0)
        item = items.pop(0)
        print(f"Consumed {item}")

async def producer():
    async with condition:
        items.append("item")
        condition.notify()  # Wake one waiter
        # condition.notify_all()  # Wake all waiters

# Barrier for synchronization
barrier = asyncio.Barrier(3)  # Wait for 3 tasks

async def worker(worker_id: int):
    print(f"Worker {worker_id} starting")
    await asyncio.sleep(worker_id)  # Different delays
    await barrier.wait()  # Wait for all
    print(f"Worker {worker_id} proceeding")

# Semaphore for resource limiting
semaphore = asyncio.Semaphore(5)  # Max 5 concurrent

async def limited_access(resource_id: int):
    async with semaphore:
        print(f"Accessing resource {resource_id}")
        await asyncio.sleep(1)
        print(f"Released resource {resource_id}")

# BoundedSemaphore (prevents releasing too many times)
bounded = asyncio.BoundedSemaphore(5)

async def safe_semaphore():
    await bounded.acquire()
    try:
        # Work
        pass
    finally:
        bounded.release()
        # bounded.release()  # Would raise ValueError
```

## Error Handling

```python
# Exception handling in tasks
async def task_with_exception():
    raise ValueError("Task failed")

async def handle_task_exception():
    task = asyncio.create_task(task_with_exception())

    try:
        await task
    except ValueError as e:
        print(f"Caught: {e}")

# Exception propagation in gather
async def gather_exceptions():
    async def failing_task():
        raise ValueError("Failed")

    async def working_task():
        return "OK"

    # Default: first exception raised
    try:
        results = await asyncio.gather(
            failing_task(),
            working_task()
        )
    except ValueError:
        print("Gather failed")

    # return_exceptions=True: exceptions in results
    results = await asyncio.gather(
        failing_task(),
        working_task(),
        return_exceptions=True
    )
    for result in results:
        if isinstance(result, Exception):
            print(f"Error: {result}")
        else:
            print(f"Result: {result}")

# Unhandled exceptions in background tasks
def handle_background_exception(task: asyncio.Task):
    """Callback for task exceptions."""
    try:
        task.result()
    except asyncio.CancelledError:
        pass  # Task was cancelled
    except Exception as e:
        print(f"Background task failed: {e}")

async def start_background_task():
    task = asyncio.create_task(background_work())
    task.add_done_callback(handle_background_exception)
    return task

# Global exception handler
def exception_handler(loop, context):
    """Handle uncaught exceptions."""
    exception = context.get("exception")
    message = context.get("message", "Unhandled exception")
    print(f"Exception handler: {message}: {exception}")

loop = asyncio.get_event_loop()
loop.set_exception_handler(exception_handler)

# Retry with exponential backoff
async def retry_with_backoff(
    coro_func,
    max_retries: int = 3,
    initial_delay: float = 1.0
):
    """Retry with exponential backoff."""
    for attempt in range(max_retries):
        try:
            return await coro_func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            delay = initial_delay * (2 ** attempt)
            print(f"Attempt {attempt + 1} failed, retrying in {delay}s")
            await asyncio.sleep(delay)
```

## Performance Optimization

```python
# Avoid blocking operations in async code
async def bad_example():
    # BAD: Blocks event loop
    import time
    time.sleep(1)  # Blocks entire event loop!

    # GOOD: Use async sleep
    await asyncio.sleep(1)

# Avoid sync I/O in async code
async def bad_io():
    # BAD: Sync file I/O blocks
    with open("file.txt") as f:
        data = f.read()

    # GOOD: Use aiofiles
    import aiofiles
    async with aiofiles.open("file.txt") as f:
        data = await f.read()

# Batch operations
async def batch_requests(urls: list[str], batch_size: int = 10):
    """Process in batches to avoid overwhelming resources."""
    results = []
    for i in range(0, len(urls), batch_size):
        batch = urls[i:i + batch_size]
        batch_results = await asyncio.gather(*[fetch_data(url) for url in batch])
        results.extend(batch_results)
        await asyncio.sleep(0.1)  # Rate limiting
    return results

# Prefetch pattern
async def prefetch_pattern(items: list[str]):
    """Overlap I/O with processing."""
    iterator = iter(items)

    # Prefetch first item
    try:
        current_task = asyncio.create_task(fetch_data(next(iterator)))
    except StopIteration:
        return

    for item in iterator:
        # Start fetching next while processing current
        next_task = asyncio.create_task(fetch_data(item))

        # Process current
        current_result = await current_task
        process_result(current_result)

        current_task = next_task

    # Process last item
    process_result(await current_task)

# Connection pooling
class ConnectionPool:
    def __init__(self, max_connections: int):
        self.semaphore = asyncio.Semaphore(max_connections)
        self.connections: list[Connection] = []

    async def acquire(self) -> Connection:
        await self.semaphore.acquire()
        if self.connections:
            return self.connections.pop()
        return await create_connection()

    async def release(self, conn: Connection):
        self.connections.append(conn)
        self.semaphore.release()

    @asynccontextmanager
    async def connection(self):
        conn = await self.acquire()
        try:
            yield conn
        finally:
            await self.release(conn)
```

## Testing Async Code

```python
import pytest

# Basic async test
@pytest.mark.asyncio
async def test_fetch_data():
    result = await fetch_data("url")
    assert result["status"] == "ok"

# Async fixtures
@pytest.fixture
async def async_client():
    client = AsyncClient()
    await client.connect()
    yield client
    await client.disconnect()

@pytest.mark.asyncio
async def test_with_fixture(async_client):
    result = await async_client.query("data")
    assert result is not None

# Mocking async functions
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_with_mock():
    mock_fetch = AsyncMock(return_value={"status": "mocked"})

    with patch("module.fetch_data", mock_fetch):
        result = await fetch_data("url")

    assert result["status"] == "mocked"
    mock_fetch.assert_called_once_with("url")

# Testing timeouts
@pytest.mark.asyncio
async def test_timeout():
    with pytest.raises(asyncio.TimeoutError):
        await asyncio.wait_for(slow_operation(), timeout=0.1)

# Testing cancellation
@pytest.mark.asyncio
async def test_cancellation():
    task = asyncio.create_task(long_task())
    await asyncio.sleep(0.1)
    task.cancel()

    with pytest.raises(asyncio.CancelledError):
        await task
```

## Common Pitfalls

### 1. Forgetting await
```python
# BAD: Returns coroutine object, doesn't execute
result = fetch_data("url")

# GOOD
result = await fetch_data("url")
```

### 2. Sequential instead of concurrent
```python
# BAD: Sequential (slow)
results = []
for url in urls:
    results.append(await fetch_data(url))

# GOOD: Concurrent (fast)
results = await asyncio.gather(*[fetch_data(url) for url in urls])
```

### 3. Blocking the event loop
```python
# BAD: Blocks event loop
def process():
    time.sleep(1)  # Blocks!

# GOOD: Use executor
async def process():
    await asyncio.to_thread(cpu_bound_work)
```

### 4. Not handling task exceptions
```python
# BAD: Exception silently ignored
task = asyncio.create_task(may_fail())

# GOOD: Add done callback or await
task.add_done_callback(handle_exception)
```

### 5. Mixing sync and async
```python
# BAD: Can't call async from sync context
def sync_func():
    result = async_func()  # Returns coroutine, doesn't run

# GOOD: Use asyncio.run (but not in async context)
def sync_func():
    result = asyncio.run(async_func())
```

### 6. Creating too many tasks
```python
# BAD: Overwhelms system
tasks = [asyncio.create_task(fetch(url)) for url in thousand_urls]

# GOOD: Use semaphore or batch
semaphore = asyncio.Semaphore(10)
async def limited_fetch(url):
    async with semaphore:
        return await fetch(url)
```

## Best Practices

1. **Always await or handle coroutines**: Don't let them leak
2. **Use gather for parallel execution**: Not sequential awaits
3. **Handle cancellation properly**: Cleanup in except CancelledError
4. **Use context managers for resources**: Ensure cleanup
5. **Limit concurrency**: Use Semaphore to avoid overload
6. **Keep tasks named**: Easier debugging
7. **Set exception handlers**: Catch unhandled exceptions
8. **Use timeout for network calls**: Prevent hanging
9. **Batch operations**: Don't create millions of tasks
10. **Profile async code**: Use async profilers, not regular ones
