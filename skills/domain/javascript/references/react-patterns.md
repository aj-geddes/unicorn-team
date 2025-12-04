# React Patterns and Best Practices

Comprehensive guide to modern React development patterns.

## Hooks

### useState Patterns

```typescript
import { useState } from 'react';

// Basic state
const [count, setCount] = useState(0);
const [name, setName] = useState('');

// With type annotation
const [user, setUser] = useState<User | null>(null);

// Lazy initialization (expensive computation)
const [data, setData] = useState(() => {
  const initialData = expensiveComputation();
  return initialData;
});

// Functional updates (when new state depends on old)
const [count, setCount] = useState(0);
setCount(prev => prev + 1); // Safer than setCount(count + 1)

// Multiple related state values
const [state, setState] = useState({
  firstName: '',
  lastName: '',
  email: ''
});

// Update object state immutably
setState(prev => ({ ...prev, email: 'new@email.com' }));

// Array state
const [items, setItems] = useState<string[]>([]);

// Add item
setItems(prev => [...prev, 'new item']);

// Remove item
setItems(prev => prev.filter(item => item !== 'remove me'));

// Update item
setItems(prev => prev.map(item =>
  item === 'old' ? 'new' : item
));

// Toggle boolean
const [isOpen, setIsOpen] = useState(false);
const toggle = () => setIsOpen(prev => !prev);
```

### useEffect Patterns

```typescript
import { useEffect, useState } from 'react';

// Run once on mount
useEffect(() => {
  console.log('Component mounted');
}, []); // Empty dependency array

// Run on every render (usually avoid this)
useEffect(() => {
  console.log('Component rendered');
}); // No dependency array

// Run when dependencies change
useEffect(() => {
  console.log(`Count changed to ${count}`);
}, [count]);

// Cleanup function
useEffect(() => {
  const timer = setInterval(() => {
    console.log('Tick');
  }, 1000);

  // Cleanup on unmount or before re-running
  return () => {
    clearInterval(timer);
  };
}, []);

// Data fetching pattern
useEffect(() => {
  let cancelled = false;

  async function fetchData() {
    try {
      const response = await fetch(`/api/users/${userId}`);
      const data = await response.json();

      if (!cancelled) {
        setUser(data);
      }
    } catch (error) {
      if (!cancelled) {
        setError(error.message);
      }
    }
  }

  fetchData();

  return () => {
    cancelled = true; // Prevent state updates after unmount
  };
}, [userId]);

// Event listener pattern
useEffect(() => {
  function handleResize() {
    setWindowSize({
      width: window.innerWidth,
      height: window.innerHeight
    });
  }

  window.addEventListener('resize', handleResize);

  return () => {
    window.removeEventListener('resize', handleResize);
  };
}, []);

// Debounced effect
useEffect(() => {
  const timeoutId = setTimeout(() => {
    // Perform search after user stops typing
    searchUsers(query);
  }, 500);

  return () => {
    clearTimeout(timeoutId);
  };
}, [query]);
```

### useRef Patterns

```typescript
import { useRef, useEffect } from 'react';

// DOM reference
function TextInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  return <input ref={inputRef} />;
}

// Mutable value that persists across renders
function Timer() {
  const intervalRef = useRef<number | null>(null);

  const start = () => {
    intervalRef.current = setInterval(() => {
      console.log('Tick');
    }, 1000);
  };

  const stop = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
  };

  useEffect(() => {
    return () => stop(); // Cleanup
  }, []);

  return (
    <div>
      <button onClick={start}>Start</button>
      <button onClick={stop}>Stop</button>
    </div>
  );
}

// Store previous value
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();

  useEffect(() => {
    ref.current = value;
  }, [value]);

  return ref.current;
}

// Usage
function Counter() {
  const [count, setCount] = useState(0);
  const prevCount = usePrevious(count);

  return (
    <div>
      <p>Current: {count}</p>
      <p>Previous: {prevCount}</p>
    </div>
  );
}

// Callback ref for dynamic elements
function MeasureElement() {
  const [height, setHeight] = useState(0);

  const measuredRef = useCallback((node: HTMLDivElement | null) => {
    if (node !== null) {
      setHeight(node.getBoundingClientRect().height);
    }
  }, []);

  return <div ref={measuredRef}>Height: {height}</div>;
}
```

### useMemo Patterns

```typescript
import { useMemo } from 'react';

// Expensive computation
function UserList({ users }: { users: User[] }) {
  const sortedUsers = useMemo(() => {
    return [...users].sort((a, b) => a.name.localeCompare(b.name));
  }, [users]);

  return <div>{/* Render sorted users */}</div>;
}

// Derived state
function ShoppingCart({ items }: { items: CartItem[] }) {
  const total = useMemo(() => {
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }, [items]);

  return <div>Total: ${total}</div>;
}

// Stable object reference
function Form() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');

  const formData = useMemo(() => ({
    firstName,
    lastName
  }), [firstName, lastName]);

  return <FormComponent data={formData} />;
}

// Filter/search results
function SearchableList({ items, query }: Props) {
  const filteredItems = useMemo(() => {
    const lowerQuery = query.toLowerCase();
    return items.filter(item =>
      item.name.toLowerCase().includes(lowerQuery)
    );
  }, [items, query]);

  return <List items={filteredItems} />;
}
```

### useCallback Patterns

```typescript
import { useCallback, memo } from 'react';

// Stable callback reference
function Parent() {
  const [count, setCount] = useState(0);

  // Without useCallback, new function on every render
  const handleClick = useCallback(() => {
    setCount(c => c + 1);
  }, []); // No dependencies needed with functional update

  return <Child onClick={handleClick} />;
}

const Child = memo(({ onClick }: { onClick: () => void }) => {
  console.log('Child rendered');
  return <button onClick={onClick}>Click</button>;
});

// With dependencies
function SearchBox() {
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState('all');

  const handleSearch = useCallback((term: string) => {
    // Use current query and filter
    searchAPI(term, filter);
  }, [filter]); // Recreated when filter changes

  return <SearchInput onSearch={handleSearch} />;
}

// Event handler with closure
function ItemList({ items }: { items: Item[] }) {
  const handleItemClick = useCallback((id: string) => {
    // This captures id from the call, not closure
    console.log(`Clicked item ${id}`);
  }, []); // Stable reference

  return (
    <div>
      {items.map(item => (
        <button key={item.id} onClick={() => handleItemClick(item.id)}>
          {item.name}
        </button>
      ))}
    </div>
  );
}
```

### Custom Hooks

```typescript
// Fetching hook
function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchUser() {
      try {
        setLoading(true);
        const response = await fetch(`/api/users/${userId}`);
        const data = await response.json();

        if (!cancelled) {
          setUser(data);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Unknown error');
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    fetchUser();

    return () => {
      cancelled = true;
    };
  }, [userId]);

  return { user, loading, error };
}

// Local storage hook
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue] as const;
}

// Debounce hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage
function SearchComponent() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 500);

  useEffect(() => {
    if (debouncedQuery) {
      searchAPI(debouncedQuery);
    }
  }, [debouncedQuery]);

  return <input value={query} onChange={e => setQuery(e.target.value)} />;
}

// Window size hook
function useWindowSize() {
  const [windowSize, setWindowSize] = useState({
    width: window.innerWidth,
    height: window.innerHeight
  });

  useEffect(() => {
    function handleResize() {
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight
      });
    }

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return windowSize;
}

// Online status hook
function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    function handleOnline() {
      setIsOnline(true);
    }

    function handleOffline() {
      setIsOnline(false);
    }

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return isOnline;
}

// Interval hook
function useInterval(callback: () => void, delay: number | null) {
  const savedCallback = useRef(callback);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    if (delay === null) return;

    const id = setInterval(() => savedCallback.current(), delay);
    return () => clearInterval(id);
  }, [delay]);
}

// Usage
function Timer() {
  const [count, setCount] = useState(0);

  useInterval(() => {
    setCount(c => c + 1);
  }, 1000);

  return <div>{count}</div>;
}
```

## Component Patterns

### Compound Components

```typescript
// Context-based compound components
interface TabsContextValue {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function Tabs({ children }: { children: React.ReactNode }) {
  const [activeTab, setActiveTab] = useState('');

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

function TabList({ children }: { children: React.ReactNode }) {
  return <div className="tab-list">{children}</div>;
}

function Tab({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('Tab must be used within Tabs');

  const { activeTab, setActiveTab } = context;

  return (
    <button
      className={activeTab === id ? 'active' : ''}
      onClick={() => setActiveTab(id)}
    >
      {children}
    </button>
  );
}

function TabPanel({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('TabPanel must be used within Tabs');

  const { activeTab } = context;

  if (activeTab !== id) return null;

  return <div className="tab-panel">{children}</div>;
}

// Usage
function App() {
  return (
    <Tabs>
      <TabList>
        <Tab id="home">Home</Tab>
        <Tab id="profile">Profile</Tab>
        <Tab id="settings">Settings</Tab>
      </TabList>

      <TabPanel id="home">Home content</TabPanel>
      <TabPanel id="profile">Profile content</TabPanel>
      <TabPanel id="settings">Settings content</TabPanel>
    </Tabs>
  );
}
```

### Render Props

```typescript
interface MousePosition {
  x: number;
  y: number;
}

interface MouseTrackerProps {
  render: (position: MousePosition) => React.ReactNode;
}

function MouseTracker({ render }: MouseTrackerProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    function handleMouseMove(e: MouseEvent) {
      setPosition({ x: e.clientX, y: e.clientY });
    }

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return <>{render(position)}</>;
}

// Usage
function App() {
  return (
    <MouseTracker
      render={({ x, y }) => (
        <div>
          Mouse position: {x}, {y}
        </div>
      )}
    />
  );
}

// Alternative: children as function
interface MouseTrackerChildrenProps {
  children: (position: MousePosition) => React.ReactNode;
}

function MouseTrackerAlt({ children }: MouseTrackerChildrenProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    function handleMouseMove(e: MouseEvent) {
      setPosition({ x: e.clientX, y: e.clientY });
    }

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return <>{children(position)}</>;
}

// Usage
<MouseTrackerAlt>
  {({ x, y }) => (
    <div>Mouse: {x}, {y}</div>
  )}
</MouseTrackerAlt>
```

### Higher-Order Components (HOC)

```typescript
// Basic HOC
function withLoading<P extends object>(
  Component: React.ComponentType<P>
) {
  return function WithLoadingComponent(
    props: P & { loading: boolean }
  ) {
    const { loading, ...rest } = props;

    if (loading) {
      return <div>Loading...</div>;
    }

    return <Component {...(rest as P)} />;
  };
}

// Usage
const UserListWithLoading = withLoading(UserList);
<UserListWithLoading users={users} loading={isLoading} />

// HOC with configuration
function withAuth(requiredRole: string) {
  return function <P extends object>(
    Component: React.ComponentType<P>
  ) {
    return function WithAuthComponent(props: P) {
      const { user } = useAuth();

      if (!user || user.role !== requiredRole) {
        return <div>Access denied</div>;
      }

      return <Component {...props} />;
    };
  };
}

// Usage
const AdminPanel = withAuth('admin')(Dashboard);

// Composing HOCs
const enhance = compose(
  withAuth('user'),
  withLoading,
  withErrorBoundary
);

const EnhancedComponent = enhance(BaseComponent);
```

### Controlled vs Uncontrolled

```typescript
// Controlled component
function ControlledInput() {
  const [value, setValue] = useState('');

  return (
    <input
      value={value}
      onChange={e => setValue(e.target.value)}
    />
  );
}

// Uncontrolled component
function UncontrolledInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  function handleSubmit() {
    console.log(inputRef.current?.value);
  }

  return (
    <>
      <input ref={inputRef} defaultValue="Initial" />
      <button onClick={handleSubmit}>Submit</button>
    </>
  );
}

// Hybrid: controlled with default
function HybridInput({
  value: controlledValue,
  onChange,
  defaultValue = ''
}: {
  value?: string;
  onChange?: (value: string) => void;
  defaultValue?: string;
}) {
  const [internalValue, setInternalValue] = useState(defaultValue);

  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;

  function handleChange(newValue: string) {
    if (!isControlled) {
      setInternalValue(newValue);
    }
    onChange?.(newValue);
  }

  return (
    <input
      value={value}
      onChange={e => handleChange(e.target.value)}
    />
  );
}

// Usage
<HybridInput /> // Uncontrolled
<HybridInput value={value} onChange={setValue} /> // Controlled
```

## Performance Optimization

### React.memo

```typescript
// Memoize component
const ExpensiveComponent = memo(function ExpensiveComponent({
  data
}: {
  data: ComplexData;
}) {
  // Expensive rendering logic
  return <div>{/* ... */}</div>;
});

// Custom comparison
const CustomMemoComponent = memo(
  function Component({ user }: { user: User }) {
    return <div>{user.name}</div>;
  },
  (prevProps, nextProps) => {
    // Return true if props are equal (skip render)
    return prevProps.user.id === nextProps.user.id;
  }
);

// Memoize with multiple props
const OptimizedList = memo(
  function List({ items, onItemClick }: Props) {
    return (
      <div>
        {items.map(item => (
          <div key={item.id} onClick={() => onItemClick(item)}>
            {item.name}
          </div>
        ))}
      </div>
    );
  }
);
```

### Code Splitting

```typescript
// Lazy load component
const LazyComponent = lazy(() => import('./LazyComponent'));

function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <LazyComponent />
    </Suspense>
  );
}

// Lazy load with error boundary
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return <div>Something went wrong</div>;
    }

    return this.props.children;
  }
}

function App() {
  return (
    <ErrorBoundary>
      <Suspense fallback={<div>Loading...</div>}>
        <LazyComponent />
      </Suspense>
    </ErrorBoundary>
  );
}

// Route-based code splitting
const Home = lazy(() => import('./routes/Home'));
const Profile = lazy(() => import('./routes/Profile'));
const Settings = lazy(() => import('./routes/Settings'));

function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### Virtualization

```typescript
// Using react-window
import { FixedSizeList } from 'react-window';

function VirtualizedList({ items }: { items: string[] }) {
  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      {items[index]}
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}

// Dynamic size list
import { VariableSizeList } from 'react-window';

function DynamicList({ items }: { items: Item[] }) {
  const listRef = useRef<VariableSizeList>(null);

  const getItemSize = (index: number) => {
    // Calculate dynamic height
    return items[index].height;
  };

  const Row = ({ index, style }: any) => (
    <div style={style}>
      {items[index].content}
    </div>
  );

  return (
    <VariableSizeList
      ref={listRef}
      height={600}
      itemCount={items.length}
      itemSize={getItemSize}
      width="100%"
    >
      {Row}
    </VariableSizeList>
  );
}
```

## State Management

### Context API

```typescript
// Create context
interface AuthContextValue {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// Provider
function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (email: string, password: string) => {
    const user = await api.login(email, password);
    setUser(user);
  };

  const logout = () => {
    setUser(null);
  };

  const value = { user, login, logout };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// Custom hook
function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

// Usage
function App() {
  return (
    <AuthProvider>
      <Dashboard />
    </AuthProvider>
  );
}

function Dashboard() {
  const { user, logout } = useAuth();

  return (
    <div>
      <p>Welcome, {user?.name}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

### useReducer Pattern

```typescript
type State = {
  count: number;
  error: string | null;
  loading: boolean;
};

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'reset' }
  | { type: 'setError'; error: string }
  | { type: 'setLoading'; loading: boolean };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + 1 };
    case 'decrement':
      return { ...state, count: state.count - 1 };
    case 'reset':
      return { ...state, count: 0 };
    case 'setError':
      return { ...state, error: action.error };
    case 'setLoading':
      return { ...state, loading: action.loading };
    default:
      return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, {
    count: 0,
    error: null,
    loading: false
  });

  return (
    <div>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <button onClick={() => dispatch({ type: 'reset' })}>Reset</button>
    </div>
  );
}
```

## Forms

### Controlled Forms

```typescript
function LoginForm() {
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));

    // Clear error on change
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  }

  function validate(): boolean {
    const newErrors: Record<string, string> = {};

    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    if (!validate()) return;

    try {
      await api.login(formData);
    } catch (error) {
      setErrors({ form: 'Login failed' });
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
        />
        {errors.email && <span>{errors.email}</span>}
      </div>

      <div>
        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={handleChange}
        />
        {errors.password && <span>{errors.password}</span>}
      </div>

      {errors.form && <div>{errors.form}</div>}

      <button type="submit">Login</button>
    </form>
  );
}
```

### Form Libraries

```typescript
// React Hook Form
import { useForm } from 'react-hook-form';

interface FormData {
  email: string;
  password: string;
}

function LoginFormRHF() {
  const {
    register,
    handleSubmit,
    formState: { errors }
  } = useForm<FormData>();

  const onSubmit = async (data: FormData) => {
    await api.login(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input
        {...register('email', {
          required: 'Email is required',
          pattern: {
            value: /\S+@\S+\.\S+/,
            message: 'Email is invalid'
          }
        })}
      />
      {errors.email && <span>{errors.email.message}</span>}

      <input
        type="password"
        {...register('password', {
          required: 'Password is required',
          minLength: {
            value: 8,
            message: 'Password must be at least 8 characters'
          }
        })}
      />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit">Login</button>
    </form>
  );
}
```
