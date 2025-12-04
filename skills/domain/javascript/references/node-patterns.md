# Node.js Patterns and Best Practices

Comprehensive guide to Node.js backend development.

## Express Patterns

### Basic Setup

```typescript
import express from 'express';
import type { Request, Response, NextFunction } from 'express';

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Async Error Handling

```typescript
// Async handler wrapper
function asyncHandler<T>(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<T>
) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// Usage
app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id);

  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }

  res.json(user);
}));

// Error handling middleware (must be last)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);

  if (err instanceof ValidationError) {
    res.status(400).json({ error: err.message });
    return;
  }

  if (err instanceof NotFoundError) {
    res.status(404).json({ error: err.message });
    return;
  }

  res.status(500).json({ error: 'Internal server error' });
});
```

### Router Organization

```typescript
// users.router.ts
import { Router } from 'express';

const router = Router();

router.get('/', asyncHandler(async (req, res) => {
  const users = await userService.findAll();
  res.json(users);
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id);
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json(user);
}));

router.post('/', asyncHandler(async (req, res) => {
  const user = await userService.create(req.body);
  res.status(201).json(user);
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const user = await userService.update(req.params.id, req.body);
  res.json(user);
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  await userService.delete(req.params.id);
  res.status(204).send();
}));

export default router;

// app.ts
import userRouter from './routes/users.router';

app.use('/api/users', userRouter);
```

### Middleware Patterns

```typescript
// Authentication middleware
interface AuthRequest extends Request {
  user?: User;
}

function authenticate(req: AuthRequest, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    res.status(401).json({ error: 'No token provided' });
    return;
  }

  try {
    const user = verifyToken(token);
    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Authorization middleware
function authorize(...roles: string[]) {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      res.status(401).json({ error: 'Not authenticated' });
      return;
    }

    if (!roles.includes(req.user.role)) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    next();
  };
}

// Usage
app.get('/admin/users',
  authenticate,
  authorize('admin'),
  asyncHandler(async (req, res) => {
    const users = await userService.findAll();
    res.json(users);
  })
);

// Request logging middleware
function logger(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} - ${res.statusCode} - ${duration}ms`);
  });

  next();
}

// Rate limiting middleware
const rateLimitMap = new Map<string, number[]>();

function rateLimit(maxRequests: number, windowMs: number) {
  return (req: Request, res: Response, next: NextFunction) => {
    const ip = req.ip;
    const now = Date.now();

    const requests = rateLimitMap.get(ip) || [];
    const validRequests = requests.filter(time => now - time < windowMs);

    if (validRequests.length >= maxRequests) {
      res.status(429).json({ error: 'Too many requests' });
      return;
    }

    validRequests.push(now);
    rateLimitMap.set(ip, validRequests);
    next();
  };
}

// Validation middleware
import { z } from 'zod';

function validate<T>(schema: z.Schema<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          error: 'Validation failed',
          details: error.errors
        });
        return;
      }
      next(error);
    }
  };
}

// Usage
const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  password: z.string().min(8)
});

app.post('/users',
  validate(createUserSchema),
  asyncHandler(async (req, res) => {
    const user = await userService.create(req.body);
    res.status(201).json(user);
  })
);
```

## Async Patterns

### Promise Patterns

```typescript
// Sequential execution
async function sequential() {
  const user = await fetchUser();
  const posts = await fetchPosts(user.id);
  const comments = await fetchComments(posts[0].id);

  return { user, posts, comments };
}

// Parallel execution
async function parallel() {
  const [users, posts, comments] = await Promise.all([
    fetchUsers(),
    fetchPosts(),
    fetchComments()
  ]);

  return { users, posts, comments };
}

// Parallel with dependencies
async function parallelWithDeps() {
  const user = await fetchUser();

  // These can run in parallel after user is fetched
  const [posts, friends] = await Promise.all([
    fetchPosts(user.id),
    fetchFriends(user.id)
  ]);

  return { user, posts, friends };
}

// Promise.allSettled - doesn't fail on single rejection
async function allSettled() {
  const results = await Promise.allSettled([
    fetchUsers(),
    fetchPosts(),
    fetchComments()
  ]);

  results.forEach((result, index) => {
    if (result.status === 'fulfilled') {
      console.log(`Request ${index} succeeded:`, result.value);
    } else {
      console.error(`Request ${index} failed:`, result.reason);
    }
  });
}

// Promise.race - first to complete
async function race() {
  const result = await Promise.race([
    fetchData(),
    timeout(5000)
  ]);

  return result;
}

function timeout(ms: number): Promise<never> {
  return new Promise((_, reject) => {
    setTimeout(() => reject(new Error('Timeout')), ms);
  });
}

// Promise.any - first to succeed
async function any() {
  try {
    const result = await Promise.any([
      fetchFromPrimary(),
      fetchFromSecondary(),
      fetchFromTertiary()
    ]);
    return result;
  } catch (error) {
    // All promises rejected
    console.error('All sources failed');
    throw error;
  }
}
```

### Queue Pattern

```typescript
class AsyncQueue {
  private queue: Array<() => Promise<any>> = [];
  private running = 0;

  constructor(private concurrency: number) {}

  async add<T>(task: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.queue.push(async () => {
        try {
          const result = await task();
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });

      this.process();
    });
  }

  private async process() {
    if (this.running >= this.concurrency || this.queue.length === 0) {
      return;
    }

    this.running++;
    const task = this.queue.shift()!;

    try {
      await task();
    } finally {
      this.running--;
      this.process();
    }
  }
}

// Usage
const queue = new AsyncQueue(3); // Max 3 concurrent tasks

const results = await Promise.all([
  queue.add(() => fetchUser(1)),
  queue.add(() => fetchUser(2)),
  queue.add(() => fetchUser(3)),
  queue.add(() => fetchUser(4)), // Waits for a slot
  queue.add(() => fetchUser(5)), // Waits for a slot
]);
```

### Retry Pattern

```typescript
async function retry<T>(
  fn: () => Promise<T>,
  options: {
    maxAttempts?: number;
    delay?: number;
    backoff?: number;
    onRetry?: (error: Error, attempt: number) => void;
  } = {}
): Promise<T> {
  const {
    maxAttempts = 3,
    delay = 1000,
    backoff = 2,
    onRetry
  } = options;

  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      if (attempt === maxAttempts) {
        throw lastError;
      }

      onRetry?.(lastError, attempt);

      const waitTime = delay * Math.pow(backoff, attempt - 1);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
  }

  throw lastError!;
}

// Usage
const user = await retry(
  () => fetchUser('123'),
  {
    maxAttempts: 5,
    delay: 1000,
    backoff: 2,
    onRetry: (error, attempt) => {
      console.log(`Attempt ${attempt} failed: ${error.message}`);
    }
  }
);
```

### Circuit Breaker Pattern

```typescript
enum CircuitState {
  CLOSED,
  OPEN,
  HALF_OPEN
}

class CircuitBreaker {
  private state = CircuitState.CLOSED;
  private failureCount = 0;
  private lastFailureTime: number | null = null;

  constructor(
    private threshold: number,
    private timeout: number
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.lastFailureTime! >= this.timeout) {
        this.state = CircuitState.HALF_OPEN;
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }

  private onFailure() {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.failureCount >= this.threshold) {
      this.state = CircuitState.OPEN;
    }
  }
}

// Usage
const breaker = new CircuitBreaker(5, 60000); // 5 failures, 60s timeout

try {
  const data = await breaker.execute(() => fetchData());
} catch (error) {
  console.error('Circuit breaker prevented call or call failed');
}
```

## Streams

### Readable Streams

```typescript
import { Readable } from 'stream';

// Create readable stream
const readable = new Readable({
  read() {
    this.push('chunk 1\n');
    this.push('chunk 2\n');
    this.push('chunk 3\n');
    this.push(null); // Signal end
  }
});

// Read data
readable.on('data', chunk => {
  console.log('Received:', chunk.toString());
});

readable.on('end', () => {
  console.log('Stream ended');
});

readable.on('error', error => {
  console.error('Stream error:', error);
});

// Async iteration
async function readStream(readable: Readable) {
  for await (const chunk of readable) {
    console.log('Chunk:', chunk.toString());
  }
}

// File stream
import { createReadStream } from 'fs';

const fileStream = createReadStream('./large-file.txt', {
  encoding: 'utf8',
  highWaterMark: 64 * 1024 // 64KB chunks
});

fileStream.on('data', chunk => {
  console.log('Read chunk:', chunk.length);
});
```

### Writable Streams

```typescript
import { Writable } from 'stream';

// Create writable stream
const writable = new Writable({
  write(chunk, encoding, callback) {
    console.log('Writing:', chunk.toString());
    callback();
  }
});

// Write data
writable.write('Hello ');
writable.write('World\n');
writable.end('Goodbye\n');

// File stream
import { createWriteStream } from 'fs';

const output = createWriteStream('./output.txt');

output.write('Line 1\n');
output.write('Line 2\n');
output.end('Line 3\n');

output.on('finish', () => {
  console.log('Write completed');
});
```

### Transform Streams

```typescript
import { Transform } from 'stream';

// Uppercase transform
const uppercase = new Transform({
  transform(chunk, encoding, callback) {
    this.push(chunk.toString().toUpperCase());
    callback();
  }
});

// Pipeline
import { pipeline } from 'stream/promises';

await pipeline(
  createReadStream('./input.txt'),
  uppercase,
  createWriteStream('./output.txt')
);

// Custom transform
class JSONParser extends Transform {
  constructor() {
    super({ objectMode: true });
  }

  _transform(chunk: any, encoding: string, callback: Function) {
    try {
      const obj = JSON.parse(chunk.toString());
      this.push(obj);
      callback();
    } catch (error) {
      callback(error);
    }
  }
}

// CSV parser
class CSVParser extends Transform {
  private header: string[] | null = null;

  constructor() {
    super({ objectMode: true });
  }

  _transform(chunk: any, encoding: string, callback: Function) {
    const lines = chunk.toString().split('\n');

    for (const line of lines) {
      if (!this.header) {
        this.header = line.split(',');
        continue;
      }

      const values = line.split(',');
      const obj = this.header.reduce((acc, key, i) => {
        acc[key] = values[i];
        return acc;
      }, {} as Record<string, string>);

      this.push(obj);
    }

    callback();
  }
}
```

### Stream Utilities

```typescript
// Pause and resume
const stream = createReadStream('./large-file.txt');

stream.on('data', chunk => {
  console.log('Chunk:', chunk.length);

  // Pause to process
  stream.pause();

  setTimeout(() => {
    stream.resume();
  }, 1000);
});

// Backpressure handling
async function copyWithBackpressure(
  source: Readable,
  destination: Writable
) {
  for await (const chunk of source) {
    const canContinue = destination.write(chunk);

    if (!canContinue) {
      // Wait for drain event
      await new Promise(resolve => destination.once('drain', resolve));
    }
  }

  destination.end();
}

// Stream composition
import { compose } from 'stream';

const composed = compose(
  createReadStream('./input.txt'),
  uppercase,
  createWriteStream('./output.txt')
);

composed.on('finish', () => {
  console.log('Pipeline finished');
});
```

## Database Patterns

### Connection Pool

```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'mydb',
  user: 'user',
  password: 'password',
  max: 20, // Maximum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Execute query
async function query<T>(text: string, params?: any[]): Promise<T[]> {
  const client = await pool.connect();

  try {
    const result = await client.query(text, params);
    return result.rows;
  } finally {
    client.release();
  }
}

// Transaction
async function transaction<T>(
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Usage
await transaction(async client => {
  await client.query('INSERT INTO users (name) VALUES ($1)', ['Alice']);
  await client.query('INSERT INTO profiles (user_id) VALUES ($1)', [1]);
});
```

### Query Builder

```typescript
class QueryBuilder {
  private selectFields: string[] = [];
  private fromTable: string = '';
  private whereConditions: string[] = [];
  private orderByFields: string[] = [];
  private limitValue: number | null = null;
  private params: any[] = [];

  select(...fields: string[]): this {
    this.selectFields = fields;
    return this;
  }

  from(table: string): this {
    this.fromTable = table;
    return this;
  }

  where(condition: string, ...params: any[]): this {
    this.whereConditions.push(condition);
    this.params.push(...params);
    return this;
  }

  orderBy(field: string, direction: 'ASC' | 'DESC' = 'ASC'): this {
    this.orderByFields.push(`${field} ${direction}`);
    return this;
  }

  limit(value: number): this {
    this.limitValue = value;
    return this;
  }

  build(): { text: string; params: any[] } {
    let text = `SELECT ${this.selectFields.join(', ')} FROM ${this.fromTable}`;

    if (this.whereConditions.length > 0) {
      text += ` WHERE ${this.whereConditions.join(' AND ')}`;
    }

    if (this.orderByFields.length > 0) {
      text += ` ORDER BY ${this.orderByFields.join(', ')}`;
    }

    if (this.limitValue !== null) {
      text += ` LIMIT ${this.limitValue}`;
    }

    return { text, params: this.params };
  }

  async execute<T>(): Promise<T[]> {
    const { text, params } = this.build();
    return query<T>(text, params);
  }
}

// Usage
const users = await new QueryBuilder()
  .select('id', 'name', 'email')
  .from('users')
  .where('age > $1', 18)
  .where('status = $2', 'active')
  .orderBy('name', 'ASC')
  .limit(10)
  .execute<User>();
```

## Error Handling

### Custom Errors

```typescript
class AppError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code?: string
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_ERROR');
  }
}

class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'NOT_FOUND');
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403, 'FORBIDDEN');
  }
}

// Usage
if (!user) {
  throw new NotFoundError('User');
}

if (!isValid(data)) {
  throw new ValidationError('Invalid email format');
}
```

### Error Handler Middleware

```typescript
function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // Log error
  console.error({
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    body: req.body
  });

  // Handle known errors
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: {
        message: err.message,
        code: err.code
      }
    });
    return;
  }

  // Handle validation errors (e.g., from express-validator)
  if (err.name === 'ValidationError') {
    res.status(400).json({
      error: {
        message: 'Validation failed',
        details: err.message
      }
    });
    return;
  }

  // Handle database errors
  if (err.name === 'QueryFailedError') {
    res.status(500).json({
      error: {
        message: 'Database error',
        code: 'DATABASE_ERROR'
      }
    });
    return;
  }

  // Default error
  res.status(500).json({
    error: {
      message: 'Internal server error',
      code: 'INTERNAL_ERROR'
    }
  });
}

app.use(errorHandler);
```

## Testing Node.js

### Testing Express Routes

```typescript
import request from 'supertest';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import app from './app';

describe('Users API', () => {
  beforeAll(async () => {
    // Setup test database
    await setupTestDb();
  });

  afterAll(async () => {
    // Cleanup
    await cleanupTestDb();
  });

  describe('GET /api/users', () => {
    it('returns list of users', async () => {
      const response = await request(app)
        .get('/api/users')
        .expect(200);

      expect(response.body).toBeInstanceOf(Array);
      expect(response.body.length).toBeGreaterThan(0);
    });

    it('requires authentication', async () => {
      await request(app)
        .get('/api/users/admin')
        .expect(401);
    });
  });

  describe('POST /api/users', () => {
    it('creates new user', async () => {
      const userData = {
        name: 'Alice',
        email: 'alice@example.com'
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      expect(response.body).toMatchObject(userData);
      expect(response.body.id).toBeDefined();
    });

    it('validates required fields', async () => {
      await request(app)
        .post('/api/users')
        .send({ name: 'Alice' }) // Missing email
        .expect(400);
    });
  });
});
```
