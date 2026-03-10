---
name: javascript
description: >-
  Guides JavaScript and TypeScript development with modern tooling and patterns.
  ALWAYS trigger on "typescript", "javascript", "tsconfig", "eslint",
  "prettier", "vitest", "jest", "react", "node.js", "express", "npm",
  "package.json", "type error", "ts error", "js project setup", "frontend
  testing", "react hooks", "discriminated union", "type guard". Use when
  configuring TS/JS tooling, writing tests, structuring React or Node apps,
  or debugging type issues. Different from testing skill which covers general
  strategy; this covers JS/TS-specific test patterns and framework configs.
---

# JavaScript/TypeScript Domain Skill

## TypeScript Essentials

Utility types (use these instead of manual definitions):

| Type | Effect |
|------|--------|
| `Pick<T, K>` | Subset of properties |
| `Omit<T, K>` | Exclude properties |
| `Partial<T>` | All optional |
| `Required<T>` | All required |
| `Record<K, V>` | Key-value map |
| `ReturnType<typeof fn>` | Extract return type |
| `Awaited<Promise<T>>` | Unwrap promise type |
| `Extract<T, U>` / `Exclude<T, U>` | Filter union members |

Generics:
```typescript
interface ApiResponse<T> {
  data: T;
  status: number;
}

function fetchData<T>(url: string): Promise<ApiResponse<T>> {
  return fetch(url).then(res => res.json());
}
```

**Advanced TypeScript:** See `references/typescript-advanced.md` for conditional types, mapped types, branded types, infer.

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

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('UserService', () => {
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

// Mocking
vi.mock('./api', () => ({ fetchUser: vi.fn() }));
vi.mocked(fetchUser).mockResolvedValue({ id: '1', name: 'Alice' });
```

React component testing:
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

**See `references/testing-examples.md`** for mocking patterns, integration tests, test factories.

## React Patterns

Custom hook with cleanup:
```typescript
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
const sorted = useMemo(() => [...items].sort(), [items]);
const handleClick = useCallback(() => doSomething(), []);
const MemoComponent = memo(({ data }: Props) => <div>{data}</div>);
```

**See `references/react-patterns.md`** for compound components, context, forms, code splitting.

## Node.js Patterns

Async handler wrapper (Express):
```typescript
function asyncHandler(fn: (req: Request, res: Response) => Promise<void>) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res)).catch(next);
  };
}

app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await userService.findById(req.params.id);
  if (!user) { res.status(404).json({ error: 'User not found' }); return; }
  res.json(user);
}));
```

**See `references/node-patterns.md`** for middleware, streams, database patterns, error handling.

## Common Patterns

Result type:
```typescript
type Result<T, E = string> =
  | { success: true; data: T }
  | { success: false; error: E };
```

Type guard:
```typescript
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj;
}
```

Discriminated union:
```typescript
type Response =
  | { status: 'success'; data: User }
  | { status: 'error'; error: string }
  | { status: 'loading' };

function handle(response: Response) {
  switch (response.status) {
    case 'success': return response.data;  // type-narrowed
    case 'error': throw new Error(response.error);
  }
}
```

## Anti-patterns Quick Reference

| Anti-pattern | Fix |
|-------------|-----|
| `any` type | Proper types or `unknown` with validation |
| Mutating arrays/objects in place | Spread: `[...arr, item]`, `{ ...obj, key: val }` |
| Nested `.then()` chains | `async`/`await` |
| Missing error handling on async | `try`/`catch` or `.catch()` |
| React state mutation `arr.push()` | `setArr(prev => [...prev, item])` |
| Missing `useEffect` deps | Include all referenced values |
| Unstable object refs in render | Hoist constants or `useMemo` |
| Circular imports | Extract shared code to `shared.ts` |
| `console.log` in production | Structured logger |
| Non-exhaustive switch on union | Add `default: assertNever(x)` |

**Naming:** camelCase (variables, functions), PascalCase (classes, types, components), SCREAMING_SNAKE_CASE (constants).

## Reference Documentation

- **`references/typescript-advanced.md`** - Generics, conditional types, mapped types, branded types
- **`references/react-patterns.md`** - Hooks, component patterns, performance, state management, forms
- **`references/node-patterns.md`** - Express, async patterns, streams, database patterns
- **`references/testing-examples.md`** - Jest/Vitest config, mocking, component testing, integration tests
