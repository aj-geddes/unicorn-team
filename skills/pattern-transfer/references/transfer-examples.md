# Pattern Transfer Examples

## Patterns Are Fractal

Same pattern at different scales:

### Observer Pattern Everywhere

```
"Notify interested parties when something changes"

Object-level (OOP):     class Subject: attach(observer), notify()
Component-level (React): useEffect(() => {...}, [dependency])
Service-level (Pub/Sub): redis.subscribe('events', callback)
System-level (Webhooks): POST https://site.com/webhook
Database-level (SQL):    CREATE TRIGGER notify_on_change...

ALL ARE THE SAME PATTERN
```

### Producer-Consumer Everywhere

```
"Decouple production from consumption with buffer"

Python threads:  queue.put(item) / queue.get()
RabbitMQ:        channel.basic_publish() / basic_consume()
Kafka:           producer.send() / consumer.subscribe()
Go channels:     ch <- value / value := <-ch

ALL SOLVE SAME PROBLEM
```

### Strategy Pattern Everywhere

```
"Swap algorithm at runtime"

Sorting:        sorter.set_strategy(QuickSort())
Payment:        checkout.set_payment_method(CreditCard())
Compression:    compressor = GzipCompressor()  # or Zip
React:          const View = isMobile ? Mobile : Desktop

SAME PATTERN, DIFFERENT DOMAINS
```

---

## Practice Examples

### Recognize the Pattern

**Debounce function**:
```javascript
function debounce(fn, delay) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), delay);
    };
}
```
**Answer**: RATE LIMITING / BATCHING (limits execution frequency)

**SQL Transaction**:
```sql
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```
**Answer**: ATOMIC OPERATIONS (all or nothing)

**Python Decorator**:
```python
def log_calls(func):
    def wrapper(*args):
        print(f"Calling {func.__name__}")
        return func(*args)
    return wrapper
```
**Answer**: ASPECT-ORIENTED / DECORATOR (add behavior without modifying original)

Transfer these patterns to different contexts using the 3-step protocol: Extract, Find Idioms, Reify.
