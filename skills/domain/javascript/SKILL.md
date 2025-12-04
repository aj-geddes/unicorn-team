---
name: javascript
description: >
  Expert JavaScript and TypeScript development guidance. Use when working with
  JS/TS codebases, implementing Node.js or browser applications, configuring
  TypeScript, setting up modern tooling (ESLint, Prettier, bundlers), writing
  tests with Jest/Vitest, or debugging type errors. Covers ES6+ features,
  async patterns, React/Node patterns, and common anti-patterns to avoid.
---

# JavaScript/TypeScript Domain Skill

Expert guidance for modern JavaScript and TypeScript development.

## TypeScript Essentials

Use interfaces for objects, types for unions:
```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

type Status = 'pending' | 'active' | 'suspended';
```

Leverage utility types:
```typescript
Pick<User, 'id' | 'name'>      // Subset of properties
Partial<User>                   // All optional
Required<User>                  // All required
Omit<User, 'email'>            // Exclude properties
ReturnType<typeof fn>          // Extract return type
```

Use generics:
```typescript
interface ApiResponse<T> {
  data: T;
  status: number;
}

function fetchData<T>(url: string): Promise<ApiResponse<T>> {
  return fetch(url).then(res => res.json());
}
```

**Advanced TypeScript:** See `references/typescript-advanced.md` for generics, conditional types, mapped types, branded types.

## Modern JavaScript

Destructuring and spread:
```typescript
const { id, name, ...rest } = user;
const updated = { ...user, name: 'New Name' };
const combined = [...arr1, ...arr2];
```

Optional chaining and nullish coalescing:
```typescript
const userName = user?.profile?.name;
const port = config.port ?? 3000;
```

Async/await:
```typescript
async function fetchUser(id: string): Promise<User> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw error;
  }
}

// Parallel execution
const [users, posts] = await Promise.all([fetchUsers(), fetchPosts()]);
```

ES Modules:
```typescript
export const PI = 3.14159;
export default class App { }

import App from './App';
import { PI } from './math';
import type { User } from './types';
```

## Configuration

### TypeScript (tsconfig.json)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022", "DOM"],
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

### ESLint

```javascript
module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
  },
};
```

### Prettier

```javascript
module.exports = {
  semi: true,
  singleQuote: true,
  trailingComma: 'all',
  printWidth: 100,
};
```

### Package Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest",
    "lint": "eslint . --ext .ts,.tsx --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx}\""
  }
}
```

## Testing

Basic structure:
```typescript
import { describe, it, expect, beforeEach } from 'vitest';

describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService();
  });

  it('fetches user data', async () => {
    const user = await service.fetchUser('123');
    expect(user).toBeDefined();
    expect(user.id).toBe('123');
  });

  it('throws on invalid ID', async () => {
    await expect(service.fetchUser('invalid'))
      .rejects.toThrow('User not found');
  });
});
```

React testing:
```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

it('submits form', async () => {
  render(<LoginForm onSubmit={vi.fn()} />);

  await userEvent.type(screen.getByLabelText(/email/i), 'test@test.com');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  await waitFor(() => {
    expect(screen.getByText(/success/i)).toBeInTheDocument();
  });
});
```

Mocking:
```typescript
import { vi } from 'vitest';

vi.mock('./api', () => ({ fetchUser: vi.fn() }));

vi.mocked(fetchUser).mockResolvedValue({ id: '1', name: 'Alice' });

const spy = vi.spyOn(console, 'error').mockImplementation(() => {});
```

**Testing patterns:** See `references/testing-examples.md`

## React Patterns

Hooks:
```typescript
// State with functional updates
const [count, setCount] = useState(0);
setCount(prev => prev + 1);

// Effect with cleanup
useEffect(() => {
  const timer = setInterval(() => {}, 1000);
  return () => clearInterval(timer);
}, []);

// Custom hook
function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    fetchUser(userId).then(data => {
      if (!cancelled) setUser(data);
      setLoading(false);
    });
    return () => { cancelled = true; };
  }, [userId]);

  return { user, loading };
}
```

Performance:
```typescript
// Memoization
const sorted = useMemo(() => [...items].sort(), [items]);
const handleClick = useCallback(() => doSomething(), []);

// Component memo
const Memo = memo(({ data }: Props) => <div>{data}</div>);
```

**React patterns:** See `references/react-patterns.md` for hooks, context, performance, forms.

## Node.js Patterns

Express setup:
```typescript
import express from 'express';
import type { Request, Response, NextFunction } from 'express';

const app = express();
app.use(express.json());

// Async handler wrapper
function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id);
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json(user);
}));

// Error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});
```

**Node.js patterns:** See `references/node-patterns.md` for Express, streams, databases, error handling.

## Common Patterns

Error handling:
```typescript
// Try/catch
async function processData(id: string) {
  try {
    const data = await fetchData(id);
    return { success: true, data };
  } catch (error) {
    if (error instanceof NetworkError) {
      return { success: false, error: 'Network unavailable' };
    }
    throw error;
  }
}

// Result types
type Result<T, E = string> =
  | { success: true; data: T }
  | { success: false; error: E };
```

API client:
```typescript
class ApiClient {
  constructor(private baseUrl: string) {}

  async get<T>(path: string): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`);
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  }

  async post<T, D>(path: string, data: D): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  }
}
```

Type guards:
```typescript
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj;
}
```

Discriminated unions:
```typescript
type Response =
  | { status: 'success'; data: User }
  | { status: 'error'; error: string }
  | { status: 'loading' };

function handle(response: Response) {
  switch (response.status) {
    case 'success':
      console.log(response.data); // Type-safe
      break;
    case 'error':
      console.error(response.error);
      break;
  }
}
```

## Anti-patterns to Avoid

Type safety:
```typescript
// Bad: any
function process(data: any) { }

// Good: proper types or unknown with validation
function process(data: { value: string }) { }
function processExternal(data: unknown) {
  if (isValidData(data)) return data.value;
  throw new Error('Invalid');
}
```

Mutation:
```typescript
// Bad
function addItem(arr: string[], item: string) {
  arr.push(item);
  return arr;
}

// Good
function addItem(arr: string[], item: string) {
  return [...arr, item];
}
```

Promise handling:
```typescript
// Bad: nested promises
fetchUser(id).then(user => {
  fetchPosts(user.id).then(posts => {});
});

// Good: async/await
const user = await fetchUser(id);
const posts = await fetchPosts(user.id);

// Bad: missing error handling
async function process() {
  const data = await fetchData(); // Unhandled
  return data;
}

// Good: try/catch
async function process() {
  try {
    return await fetchData();
  } catch (error) {
    console.error('Failed:', error);
    throw error;
  }
}
```

React anti-patterns:
```typescript
// Bad: direct mutation
const [items, setItems] = useState<string[]>([]);
items.push('new');

// Good: immutable
setItems([...items, 'new']);
setItems(prev => [...prev, 'new']);

// Bad: missing deps
useEffect(() => {
  fetchData(userId);
}, []);

// Good: include deps
useEffect(() => {
  fetchData(userId);
}, [userId]);

// Bad: unstable reference
function Component() {
  const config = { option: true };
  return <Child config={config} />;
}

// Good: stable reference
const config = { option: true };
function Component() {
  return <Child config={config} />;
}
```

Circular dependencies:
```typescript
// Bad: a.ts imports b.ts, b.ts imports a.ts
// Good: Extract shared code to shared.ts
```

Naming: camelCase (variables, functions), PascalCase (classes, types, components), SCREAMING_SNAKE_CASE (constants).

## Reference Documentation

Comprehensive guides with advanced patterns and examples:

- **`references/typescript-advanced.md`** - Advanced TypeScript
  - Generics (constraints, defaults, conditional types)
  - Utility types (built-in and custom)
  - Type guards and assertion functions
  - Conditional types and infer keyword
  - Mapped types and template literals
  - Branded types and phantom types
  - Advanced patterns (builder, state machine)

- **`references/react-patterns.md`** - React patterns
  - Hooks (useState, useEffect, useRef, useMemo, useCallback)
  - Custom hooks patterns
  - Component patterns (compound, render props, HOC)
  - Performance optimization (memo, code splitting, virtualization)
  - State management (Context, useReducer)
  - Forms (controlled, uncontrolled, libraries)

- **`references/node-patterns.md`** - Node.js backend
  - Express patterns (routing, middleware, error handling)
  - Async patterns (queues, retry, circuit breaker)
  - Streams (readable, writable, transform)
  - Database patterns (connection pools, query builders)
  - Testing Node.js applications

- **`references/testing-examples.md`** - Testing
  - Jest/Vitest configuration
  - Unit testing (functions, classes, async)
  - Mocking (functions, modules, spies, timers)
  - React component testing
  - Integration testing (API, database)
  - Test utilities and factories
