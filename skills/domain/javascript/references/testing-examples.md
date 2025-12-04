# Testing Patterns and Examples

Comprehensive guide to testing JavaScript/TypeScript applications.

## Jest/Vitest Configuration

### Basic Setup

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node', // or 'jsdom' for browser
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.test.ts',
        '**/*.spec.ts'
      ]
    },
    setupFiles: ['./test/setup.ts']
  }
});

// test/setup.ts
import { beforeAll, afterAll, beforeEach, afterEach } from 'vitest';

beforeAll(() => {
  // Global setup
});

afterAll(() => {
  // Global cleanup
});

beforeEach(() => {
  // Reset before each test
});

afterEach(() => {
  // Cleanup after each test
});
```

## Unit Testing

### Testing Functions

```typescript
import { describe, it, expect } from 'vitest';

// Pure function
function add(a: number, b: number): number {
  return a + b;
}

describe('add', () => {
  it('adds two positive numbers', () => {
    expect(add(2, 3)).toBe(5);
  });

  it('adds negative numbers', () => {
    expect(add(-2, -3)).toBe(-5);
  });

  it('adds zero', () => {
    expect(add(5, 0)).toBe(5);
  });
});

// Function with side effects
function saveToLocalStorage(key: string, value: any): void {
  localStorage.setItem(key, JSON.stringify(value));
}

describe('saveToLocalStorage', () => {
  it('saves data to localStorage', () => {
    const data = { id: '1', name: 'Alice' };

    saveToLocalStorage('user', data);

    const saved = localStorage.getItem('user');
    expect(JSON.parse(saved!)).toEqual(data);
  });

  it('overwrites existing data', () => {
    saveToLocalStorage('key', 'old');
    saveToLocalStorage('key', 'new');

    expect(localStorage.getItem('key')).toBe(JSON.stringify('new'));
  });
});
```

### Testing Classes

```typescript
class UserService {
  constructor(private api: ApiClient) {}

  async getUser(id: string): Promise<User> {
    return this.api.get(`/users/${id}`);
  }

  async createUser(data: CreateUserDto): Promise<User> {
    return this.api.post('/users', data);
  }
}

describe('UserService', () => {
  let service: UserService;
  let mockApi: ApiClient;

  beforeEach(() => {
    mockApi = {
      get: vi.fn(),
      post: vi.fn()
    } as any;

    service = new UserService(mockApi);
  });

  describe('getUser', () => {
    it('fetches user by id', async () => {
      const mockUser = { id: '1', name: 'Alice' };
      vi.mocked(mockApi.get).mockResolvedValue(mockUser);

      const user = await service.getUser('1');

      expect(mockApi.get).toHaveBeenCalledWith('/users/1');
      expect(user).toEqual(mockUser);
    });

    it('throws error when user not found', async () => {
      vi.mocked(mockApi.get).mockRejectedValue(new Error('Not found'));

      await expect(service.getUser('invalid'))
        .rejects
        .toThrow('Not found');
    });
  });

  describe('createUser', () => {
    it('creates new user', async () => {
      const userData = { name: 'Bob', email: 'bob@example.com' };
      const mockUser = { id: '2', ...userData };
      vi.mocked(mockApi.post).mockResolvedValue(mockUser);

      const user = await service.createUser(userData);

      expect(mockApi.post).toHaveBeenCalledWith('/users', userData);
      expect(user).toEqual(mockUser);
    });
  });
});
```

### Testing Async Code

```typescript
// Async/await
describe('async operations', () => {
  it('resolves with data', async () => {
    const data = await fetchData();
    expect(data).toBeDefined();
  });

  it('rejects with error', async () => {
    await expect(fetchInvalidData()).rejects.toThrow('Invalid data');
  });

  it('handles timeout', async () => {
    await expect(fetchWithTimeout(100)).rejects.toThrow('Timeout');
  }, 10000); // Increase test timeout
});

// Promises
describe('promise operations', () => {
  it('resolves promise', () => {
    return fetchData().then(data => {
      expect(data).toBeDefined();
    });
  });

  it('rejects promise', () => {
    return expect(fetchInvalidData()).rejects.toThrow();
  });
});

// Callbacks
describe('callback operations', () => {
  it('calls callback with data', done => {
    fetchData((error, data) => {
      expect(error).toBeNull();
      expect(data).toBeDefined();
      done();
    });
  });

  it('calls callback with error', done => {
    fetchInvalidData((error, data) => {
      expect(error).toBeDefined();
      expect(data).toBeUndefined();
      done();
    });
  });
});
```

## Mocking

### Function Mocks

```typescript
import { vi } from 'vitest';

// Mock function
const mockFn = vi.fn();

mockFn('arg1', 'arg2');

expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(1);
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');

// Mock implementation
const mockAdd = vi.fn((a: number, b: number) => a + b);
expect(mockAdd(2, 3)).toBe(5);

// Mock return value
const mockFetch = vi.fn();
mockFetch.mockReturnValue('result');
expect(mockFetch()).toBe('result');

// Mock resolved value
mockFetch.mockResolvedValue({ data: 'result' });
await expect(mockFetch()).resolves.toEqual({ data: 'result' });

// Mock rejected value
mockFetch.mockRejectedValue(new Error('Failed'));
await expect(mockFetch()).rejects.toThrow('Failed');

// Mock implementation once
mockFetch
  .mockReturnValueOnce('first')
  .mockReturnValueOnce('second')
  .mockReturnValue('default');

expect(mockFetch()).toBe('first');
expect(mockFetch()).toBe('second');
expect(mockFetch()).toBe('default');
expect(mockFetch()).toBe('default');

// Clear mock
mockFn.mockClear(); // Clear call history
mockFn.mockReset(); // Clear calls and implementation
mockFn.mockRestore(); // Restore original implementation
```

### Module Mocks

```typescript
// Mock entire module
vi.mock('./api', () => ({
  fetchUser: vi.fn(),
  createUser: vi.fn()
}));

import { fetchUser, createUser } from './api';

// Now these are mock functions
vi.mocked(fetchUser).mockResolvedValue({ id: '1', name: 'Alice' });

// Partial mock
vi.mock('./utils', async () => {
  const actual = await vi.importActual<typeof import('./utils')>('./utils');
  return {
    ...actual,
    fetchUser: vi.fn() // Only mock fetchUser
  };
});

// Mock with factory
vi.mock('./config', () => ({
  default: {
    apiUrl: 'http://test.com',
    timeout: 5000
  }
}));

// Spy on module
import * as utils from './utils';

vi.spyOn(utils, 'fetchUser').mockResolvedValue({ id: '1', name: 'Alice' });

// Restore after test
afterEach(() => {
  vi.restoreAllMocks();
});
```

### Spying

```typescript
// Spy on object method
const user = {
  getName: () => 'Alice',
  setName: (name: string) => { /* ... */ }
};

const spy = vi.spyOn(user, 'getName');

user.getName();

expect(spy).toHaveBeenCalled();
expect(spy).toHaveReturnedWith('Alice');

spy.mockRestore();

// Spy on global
const consoleSpy = vi.spyOn(console, 'log');

console.log('test');

expect(consoleSpy).toHaveBeenCalledWith('test');

consoleSpy.mockRestore();

// Spy with implementation
const mathSpy = vi.spyOn(Math, 'random').mockReturnValue(0.5);

expect(Math.random()).toBe(0.5);

mathSpy.mockRestore();
```

### Timer Mocks

```typescript
// Fake timers
vi.useFakeTimers();

const callback = vi.fn();
setTimeout(callback, 1000);

// Fast-forward time
vi.advanceTimersByTime(1000);
expect(callback).toHaveBeenCalled();

// Run all timers
setTimeout(callback, 5000);
vi.runAllTimers();
expect(callback).toHaveBeenCalledTimes(2);

// Run pending timers
vi.runOnlyPendingTimers();

// Restore real timers
vi.useRealTimers();

// Specific date
vi.setSystemTime(new Date('2024-01-01'));
expect(new Date().getFullYear()).toBe(2024);

vi.useRealTimers();
```

## Testing React Components

### Component Rendering

```typescript
import { render, screen } from '@testing-library/react';
import { UserProfile } from './UserProfile';

describe('UserProfile', () => {
  it('renders user name', () => {
    render(<UserProfile name="Alice" />);

    expect(screen.getByText('Alice')).toBeInTheDocument();
  });

  it('renders with default props', () => {
    render(<UserProfile />);

    expect(screen.getByText('Guest')).toBeInTheDocument();
  });

  it('renders multiple elements', () => {
    render(<UserProfile name="Alice" email="alice@example.com" />);

    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.getByText('alice@example.com')).toBeInTheDocument();
  });
});
```

### User Interactions

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Counter } from './Counter';

describe('Counter', () => {
  it('increments count on button click', async () => {
    render(<Counter />);

    const button = screen.getByRole('button', { name: /increment/i });

    expect(screen.getByText('Count: 0')).toBeInTheDocument();

    await userEvent.click(button);

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('types in input field', async () => {
    render(<SearchBox />);

    const input = screen.getByRole('textbox');

    await userEvent.type(input, 'search query');

    expect(input).toHaveValue('search query');
  });

  it('selects option from dropdown', async () => {
    render(<Dropdown />);

    const select = screen.getByRole('combobox');

    await userEvent.selectOptions(select, 'option-2');

    expect(select).toHaveValue('option-2');
  });

  it('checks checkbox', async () => {
    render(<Form />);

    const checkbox = screen.getByRole('checkbox');

    await userEvent.click(checkbox);

    expect(checkbox).toBeChecked();
  });
});
```

### Query Methods

```typescript
// getBy - throws if not found
const element = screen.getByText('Hello');
const button = screen.getByRole('button', { name: /submit/i });
const input = screen.getByLabelText('Email');
const heading = screen.getByRole('heading', { level: 1 });

// queryBy - returns null if not found
const missing = screen.queryByText('Not there');
expect(missing).toBeNull();

// findBy - async, waits for element
const asyncElement = await screen.findByText('Loaded data');

// getAllBy - returns array
const items = screen.getAllByRole('listitem');
expect(items).toHaveLength(3);

// queryAllBy - returns empty array if not found
const missing = screen.queryAllByText('Not there');
expect(missing).toHaveLength(0);

// findAllBy - async, returns array
const asyncItems = await screen.findAllByRole('listitem');

// Custom query
const { container } = render(<Component />);
const element = container.querySelector('.custom-class');

// Within
const form = screen.getByRole('form');
const submitButton = within(form).getByRole('button', { name: /submit/i });
```

### Testing Hooks

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useUser } from './useUser';

describe('useUser', () => {
  it('fetches user data', async () => {
    const { result } = renderHook(() => useUser('123'));

    expect(result.current.loading).toBe(true);
    expect(result.current.user).toBeNull();

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.user).toEqual({
      id: '123',
      name: 'Alice'
    });
  });

  it('handles error', async () => {
    vi.mocked(fetchUser).mockRejectedValue(new Error('Failed'));

    const { result } = renderHook(() => useUser('invalid'));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe('Failed');
    expect(result.current.user).toBeNull();
  });

  it('refetches on id change', async () => {
    const { result, rerender } = renderHook(
      ({ id }) => useUser(id),
      { initialProps: { id: '1' } }
    );

    await waitFor(() => {
      expect(result.current.user?.id).toBe('1');
    });

    rerender({ id: '2' });

    await waitFor(() => {
      expect(result.current.user?.id).toBe('2');
    });
  });
});
```

### Testing Context

```typescript
import { render, screen } from '@testing-library/react';
import { AuthProvider, useAuth } from './AuthContext';

function TestComponent() {
  const { user, login } = useAuth();

  return (
    <div>
      <p>{user ? user.name : 'Not logged in'}</p>
      <button onClick={() => login('test@example.com', 'password')}>
        Login
      </button>
    </div>
  );
}

describe('AuthContext', () => {
  it('provides auth context', () => {
    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    );

    expect(screen.getByText('Not logged in')).toBeInTheDocument();
  });

  it('logs in user', async () => {
    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    );

    await userEvent.click(screen.getByRole('button', { name: /login/i }));

    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument();
    });
  });
});
```

## Integration Testing

### API Integration

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

// Mock server
const server = setupServer(
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      name: 'Alice'
    });
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({
      id: '123',
      ...body
    }, { status: 201 });
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('User API', () => {
  it('fetches user', async () => {
    const user = await fetchUser('1');

    expect(user).toEqual({
      id: '1',
      name: 'Alice'
    });
  });

  it('creates user', async () => {
    const user = await createUser({
      name: 'Bob',
      email: 'bob@example.com'
    });

    expect(user).toMatchObject({
      id: '123',
      name: 'Bob',
      email: 'bob@example.com'
    });
  });

  it('handles error', async () => {
    server.use(
      http.get('/api/users/:id', () => {
        return new HttpResponse(null, { status: 404 });
      })
    );

    await expect(fetchUser('invalid')).rejects.toThrow();
  });
});
```

### Database Testing

```typescript
import { beforeAll, afterAll, beforeEach } from 'vitest';
import { createTestDb, cleanupDb, resetDb } from './test-utils';

let db: Database;

beforeAll(async () => {
  db = await createTestDb();
});

afterAll(async () => {
  await cleanupDb(db);
});

beforeEach(async () => {
  await resetDb(db);
});

describe('UserRepository', () => {
  it('creates user', async () => {
    const repo = new UserRepository(db);

    const user = await repo.create({
      name: 'Alice',
      email: 'alice@example.com'
    });

    expect(user.id).toBeDefined();

    const found = await repo.findById(user.id);
    expect(found).toEqual(user);
  });

  it('updates user', async () => {
    const repo = new UserRepository(db);

    const user = await repo.create({
      name: 'Alice',
      email: 'alice@example.com'
    });

    await repo.update(user.id, { name: 'Alice Updated' });

    const updated = await repo.findById(user.id);
    expect(updated.name).toBe('Alice Updated');
  });
});
```

## Test Utilities

### Custom Matchers

```typescript
import { expect } from 'vitest';

expect.extend({
  toBeWithinRange(received: number, min: number, max: number) {
    const pass = received >= min && received <= max;

    return {
      pass,
      message: () =>
        pass
          ? `Expected ${received} not to be within range ${min} - ${max}`
          : `Expected ${received} to be within range ${min} - ${max}`
    };
  }
});

// Usage
expect(5).toBeWithinRange(1, 10);
```

### Test Factories

```typescript
// User factory
let userId = 0;

function createUser(overrides?: Partial<User>): User {
  return {
    id: `user-${++userId}`,
    name: 'Test User',
    email: 'test@example.com',
    createdAt: new Date(),
    ...overrides
  };
}

// Usage
const user1 = createUser();
const user2 = createUser({ name: 'Alice' });
const user3 = createUser({ email: 'alice@example.com' });

// Builder pattern
class UserBuilder {
  private user: Partial<User> = {};

  withName(name: string): this {
    this.user.name = name;
    return this;
  }

  withEmail(email: string): this {
    this.user.email = email;
    return this;
  }

  build(): User {
    return {
      id: `user-${++userId}`,
      name: 'Test User',
      email: 'test@example.com',
      createdAt: new Date(),
      ...this.user
    };
  }
}

// Usage
const user = new UserBuilder()
  .withName('Alice')
  .withEmail('alice@example.com')
  .build();
```

### Snapshot Testing

```typescript
import { expect } from 'vitest';

describe('UserProfile', () => {
  it('matches snapshot', () => {
    const { container } = render(<UserProfile name="Alice" />);

    expect(container).toMatchSnapshot();
  });

  it('matches inline snapshot', () => {
    const data = { id: '1', name: 'Alice' };

    expect(data).toMatchInlineSnapshot(`
      {
        "id": "1",
        "name": "Alice",
      }
    `);
  });
});
```
