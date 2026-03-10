# Advanced TypeScript Patterns

Comprehensive guide to advanced TypeScript features and patterns.

## Generics

### Basic Generics

```typescript
// Generic function
function identity<T>(arg: T): T {
  return arg;
}

const num = identity<number>(42);
const str = identity('hello'); // Type inference works

// Generic interface
interface Box<T> {
  value: T;
  getValue(): T;
  setValue(value: T): void;
}

const numberBox: Box<number> = {
  value: 42,
  getValue() { return this.value; },
  setValue(value) { this.value = value; }
};

// Generic class
class Storage<T> {
  private items: T[] = [];

  add(item: T): void {
    this.items.push(item);
  }

  get(index: number): T | undefined {
    return this.items[index];
  }

  getAll(): T[] {
    return [...this.items];
  }
}

const userStorage = new Storage<User>();
userStorage.add({ id: '1', name: 'Alice' });
```

### Generic Constraints

```typescript
// Extend constraint
interface HasId {
  id: string;
}

function findById<T extends HasId>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}

// Multiple constraints
interface HasTimestamp {
  createdAt: Date;
}

function sortByDate<T extends HasId & HasTimestamp>(items: T[]): T[] {
  return [...items].sort((a, b) =>
    a.createdAt.getTime() - b.createdAt.getTime()
  );
}

// Keyof constraint
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { id: '1', name: 'Alice', age: 30 };
const name = getProperty(user, 'name'); // Type: string
const age = getProperty(user, 'age');   // Type: number
// getProperty(user, 'invalid'); // Error: not a valid key

// Constrain to specific types
function merge<T extends object, U extends object>(obj1: T, obj2: U): T & U {
  return { ...obj1, ...obj2 };
}
```

### Generic Default Parameters

```typescript
interface ApiResponse<T = unknown> {
  data: T;
  status: number;
  message: string;
}

// Use default
const response: ApiResponse = {
  data: 'anything',
  status: 200,
  message: 'OK'
};

// Override default
const userResponse: ApiResponse<User> = {
  data: { id: '1', name: 'Alice' },
  status: 200,
  message: 'OK'
};

// Multiple defaults
interface PaginatedResponse<T = unknown, M = {}> {
  items: T[];
  total: number;
  metadata: M;
}
```

### Conditional Types in Generics

```typescript
type AsyncReturnType<T> = T extends (...args: any[]) => Promise<infer R>
  ? R
  : never;

async function fetchUser(): Promise<User> {
  // ...
}

type UserType = AsyncReturnType<typeof fetchUser>; // User

// Extract array element type
type ElementType<T> = T extends (infer E)[] ? E : T;

type StringArray = ElementType<string[]>; // string
type NumberType = ElementType<number>;    // number

// Unwrap nested arrays
type DeepElementType<T> = T extends (infer E)[]
  ? DeepElementType<E>
  : T;

type Deep = DeepElementType<string[][][]>; // string
```

## Utility Types

### Built-in Utility Types

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  age: number;
  createdAt: Date;
  updatedAt: Date;
}

// Partial - Make all properties optional
type PartialUser = Partial<User>;
// { id?: string; name?: string; ... }

// Required - Make all properties required
type RequiredUser = Required<PartialUser>;

// Readonly - Make all properties readonly
type ReadonlyUser = Readonly<User>;
// const user: ReadonlyUser = ...;
// user.name = 'Bob'; // Error

// Pick - Select subset of properties
type UserPreview = Pick<User, 'id' | 'name'>;
// { id: string; name: string }

// Omit - Exclude properties
type UserWithoutDates = Omit<User, 'createdAt' | 'updatedAt'>;
// { id: string; name: string; email: string; age: number }

// Record - Create object type with specific keys and values
type UserRoles = Record<string, 'admin' | 'user' | 'guest'>;
const roles: UserRoles = {
  'user-1': 'admin',
  'user-2': 'user',
};

// Extract - Extract types from union
type Status = 'pending' | 'active' | 'suspended' | 'deleted';
type ActiveStatus = Extract<Status, 'active' | 'pending'>; // 'active' | 'pending'

// Exclude - Exclude types from union
type InactiveStatus = Exclude<Status, 'active' | 'pending'>; // 'suspended' | 'deleted'

// NonNullable - Remove null and undefined
type MaybeString = string | null | undefined;
type DefiniteString = NonNullable<MaybeString>; // string

// ReturnType - Extract function return type
function createUser(): User { /* ... */ }
type UserType = ReturnType<typeof createUser>; // User

// Parameters - Extract function parameters
function updateUser(id: string, data: Partial<User>): void { /* ... */ }
type UpdateParams = Parameters<typeof updateUser>; // [string, Partial<User>]

// ConstructorParameters - Extract constructor parameters
class UserService {
  constructor(apiUrl: string, timeout: number) { /* ... */ }
}
type ServiceParams = ConstructorParameters<typeof UserService>; // [string, number]

// InstanceType - Get instance type of class
type ServiceInstance = InstanceType<typeof UserService>; // UserService

// Awaited - Unwrap Promise type
type UserPromise = Promise<User>;
type UnwrappedUser = Awaited<UserPromise>; // User

// Deep awaited
type NestedPromise = Promise<Promise<Promise<User>>>;
type DeepUnwrapped = Awaited<NestedPromise>; // User
```

### Custom Utility Types

```typescript
// Deep Partial
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

interface Config {
  server: {
    host: string;
    port: number;
  };
  database: {
    url: string;
    pool: number;
  };
}

const partialConfig: DeepPartial<Config> = {
  server: { port: 3000 } // host is optional
};

// Deep Readonly
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? DeepReadonly<T[P]>
    : T[P];
};

// Mutable (opposite of Readonly)
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};

type MutableUser = Mutable<Readonly<User>>;

// Optional subset
type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

type UserWithOptionalEmail = Optional<User, 'email'>;
// { id: string; name: string; age: number; email?: string; ... }

// Required subset
type RequiredKeys<T, K extends keyof T> = T & Required<Pick<T, K>>;

// Nullable
type Nullable<T> = T | null;

// Maybe (null or undefined)
type Maybe<T> = T | null | undefined;

// ValueOf - Get union of all property values
type ValueOf<T> = T[keyof T];

interface Colors {
  red: '#FF0000';
  green: '#00FF00';
  blue: '#0000FF';
}

type ColorValue = ValueOf<Colors>; // '#FF0000' | '#00FF00' | '#0000FF'

// Function property names
type FunctionPropertyNames<T> = {
  [K in keyof T]: T[K] extends Function ? K : never;
}[keyof T];

type NonFunctionPropertyNames<T> = {
  [K in keyof T]: T[K] extends Function ? never : K;
}[keyof T];

class Service {
  name: string = '';
  count: number = 0;

  start(): void { }
  stop(): void { }
}

type MethodNames = FunctionPropertyNames<Service>; // 'start' | 'stop'
type DataNames = NonFunctionPropertyNames<Service>; // 'name' | 'count'

// Promisify - Convert sync function to async
type Promisify<T extends (...args: any[]) => any> = (
  ...args: Parameters<T>
) => Promise<ReturnType<T>>;

function syncFn(x: number): string {
  return x.toString();
}

const asyncFn: Promisify<typeof syncFn> = async (x) => {
  return x.toString();
};
```

## Type Guards

### Built-in Type Guards

```typescript
// typeof
function processValue(value: string | number) {
  if (typeof value === 'string') {
    return value.toUpperCase(); // TypeScript knows it's string
  } else {
    return value.toFixed(2); // TypeScript knows it's number
  }
}

// instanceof
class NetworkError extends Error {
  constructor(public statusCode: number, message: string) {
    super(message);
  }
}

function handleError(error: Error) {
  if (error instanceof NetworkError) {
    console.error(`HTTP ${error.statusCode}: ${error.message}`);
  } else {
    console.error(error.message);
  }
}

// in operator
interface Dog {
  bark(): void;
}

interface Cat {
  meow(): void;
}

function makeSound(animal: Dog | Cat) {
  if ('bark' in animal) {
    animal.bark();
  } else {
    animal.meow();
  }
}

// Array.isArray
function processInput(input: string | string[]) {
  if (Array.isArray(input)) {
    return input.map(s => s.toUpperCase());
  } else {
    return input.toUpperCase();
  }
}
```

### Custom Type Guards

```typescript
// User-defined type guard
interface User {
  id: string;
  name: string;
  email: string;
}

function isUser(obj: unknown): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'name' in obj &&
    'email' in obj &&
    typeof (obj as any).id === 'string' &&
    typeof (obj as any).name === 'string' &&
    typeof (obj as any).email === 'string'
  );
}

// Usage
function processData(data: unknown) {
  if (isUser(data)) {
    console.log(data.name); // TypeScript knows it's User
  }
}

// Array type guard
function isStringArray(arr: unknown): arr is string[] {
  return Array.isArray(arr) && arr.every(item => typeof item === 'string');
}

// Null check type guard
function isDefined<T>(value: T | null | undefined): value is T {
  return value !== null && value !== undefined;
}

const values = ['a', null, 'b', undefined, 'c'];
const defined = values.filter(isDefined); // string[]

// Property existence type guard
function hasProperty<K extends string>(
  obj: object,
  key: K
): obj is Record<K, unknown> {
  return key in obj;
}

// Union narrowing
type Success = { status: 'success'; data: User };
type Failure = { status: 'error'; error: string };
type Loading = { status: 'loading' };
type Response = Success | Failure | Loading;

function isSuccess(response: Response): response is Success {
  return response.status === 'success';
}

function isFailure(response: Response): response is Failure {
  return response.status === 'error';
}

// Generic type guard
function hasKey<K extends string>(
  obj: object,
  key: K
): obj is Record<K, unknown> {
  return key in obj;
}

function getProperty<T extends object, K extends string>(
  obj: T,
  key: K
): K extends keyof T ? T[K] : unknown {
  if (hasKey(obj, key)) {
    return obj[key];
  }
  return undefined as any;
}
```

### Assertion Functions

```typescript
// Assert functions (throw on false)
function assert(condition: unknown, message?: string): asserts condition {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

function assertIsUser(obj: unknown): asserts obj is User {
  assert(
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'name' in obj,
    'Invalid user object'
  );
}

// Usage
function processUser(data: unknown) {
  assertIsUser(data);
  // TypeScript now knows data is User
  console.log(data.name);
}

// Assert non-null
function assertDefined<T>(value: T | null | undefined): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error('Value is null or undefined');
  }
}

const maybeUser: User | null = getUser();
assertDefined(maybeUser);
console.log(maybeUser.name); // TypeScript knows it's not null
```

## Conditional Types

### Basic Conditional Types

```typescript
// T extends U ? X : Y
type IsString<T> = T extends string ? true : false;

type A = IsString<string>;  // true
type B = IsString<number>;  // false

// Exclude null/undefined
type NonNullable<T> = T extends null | undefined ? never : T;

type C = NonNullable<string | null>; // string

// Extract function types
type FunctionType<T> = T extends (...args: any[]) => any ? T : never;

type D = FunctionType<() => void>;  // () => void
type E = FunctionType<string>;      // never
```

### Infer Keyword

```typescript
// Infer return type
type GetReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

function getUser(): User { /* ... */ }
type UserReturn = GetReturnType<typeof getUser>; // User

// Infer parameter types
type GetFirstParam<T> = T extends (first: infer F, ...rest: any[]) => any
  ? F
  : never;

function updateUser(id: string, data: Partial<User>): void { /* ... */ }
type FirstParam = GetFirstParam<typeof updateUser>; // string

// Infer array element
type ElementOf<T> = T extends (infer E)[] ? E : never;

type StringElement = ElementOf<string[]>; // string

// Infer Promise value
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

type UserPromise = UnwrapPromise<Promise<User>>; // User
type DirectUser = UnwrapPromise<User>; // User

// Infer object property
type GetPropertyType<T, K> = K extends keyof T
  ? T[K]
  : never;

type UserName = GetPropertyType<User, 'name'>; // string

// Nested infer
type DeepUnwrap<T> = T extends Promise<infer U>
  ? DeepUnwrap<U>
  : T extends (infer E)[]
  ? DeepUnwrap<E>
  : T;

type Nested = DeepUnwrap<Promise<Promise<User[]>>>; // User
```

### Distributive Conditional Types

```typescript
// Distributes over union types
type ToArray<T> = T extends any ? T[] : never;

type StrOrNum = ToArray<string | number>;
// string[] | number[] (distributed)
// NOT (string | number)[]

// Non-distributive (wrap in tuple)
type ToArrayNonDist<T> = [T] extends [any] ? T[] : never;

type Combined = ToArrayNonDist<string | number>;
// (string | number)[]

// Practical example: filtering union
type ExtractStrings<T> = T extends string ? T : never;

type Mixed = 'a' | 1 | 'b' | 2 | 'c';
type Strings = ExtractStrings<Mixed>; // 'a' | 'b' | 'c'

// Remove specific types
type RemoveNull<T> = T extends null ? never : T;

type WithoutNull = RemoveNull<string | null | number>; // string | number
```

## Mapped Types

### Basic Mapping

```typescript
// Make all properties optional
type MyPartial<T> = {
  [P in keyof T]?: T[P];
};

// Make all properties readonly
type MyReadonly<T> = {
  readonly [P in keyof T]: T[P];
};

// Make all properties mutable (remove readonly)
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};

// Make all properties required (remove optional)
type Required<T> = {
  [P in keyof T]-?: T[P];
};
```

### Advanced Mapping

```typescript
// Transform property types
type Stringify<T> = {
  [P in keyof T]: string;
};

interface Numbers {
  a: number;
  b: number;
}

type StringNumbers = Stringify<Numbers>;
// { a: string; b: string; }

// Nullable properties
type Nullable<T> = {
  [P in keyof T]: T[P] | null;
};

// Getter types
type Getters<T> = {
  [P in keyof T as `get${Capitalize<string & P>}`]: () => T[P];
};

interface Person {
  name: string;
  age: number;
}

type PersonGetters = Getters<Person>;
// {
//   getName: () => string;
//   getAge: () => number;
// }

// Key remapping
type RemapKeys<T> = {
  [P in keyof T as `${string & P}_modified`]: T[P];
};

type Remapped = RemapKeys<{ foo: string; bar: number }>;
// { foo_modified: string; bar_modified: number; }

// Conditional property inclusion
type PickByType<T, U> = {
  [P in keyof T as T[P] extends U ? P : never]: T[P];
};

interface Mixed {
  name: string;
  age: number;
  email: string;
  active: boolean;
}

type StringProps = PickByType<Mixed, string>;
// { name: string; email: string; }

// Exclude properties by type
type OmitByType<T, U> = {
  [P in keyof T as T[P] extends U ? never : P]: T[P];
};

type NonStrings = OmitByType<Mixed, string>;
// { age: number; active: boolean; }
```

### Template Literal Types

```typescript
// String unions
type EventNames = 'click' | 'focus' | 'blur';
type EventHandlers = `on${Capitalize<EventNames>}`;
// 'onClick' | 'onFocus' | 'onBlur'

// Combining string literals
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type Endpoint = '/users' | '/posts' | '/comments';
type APIRoute = `${HTTPMethod} ${Endpoint}`;
// 'GET /users' | 'GET /posts' | ... (all combinations)

// Property paths
type PropPath<T> = T extends object
  ? {
      [K in keyof T & string]: K | `${K}.${PropPath<T[K]>}`;
    }[keyof T & string]
  : never;

interface Nested {
  user: {
    profile: {
      name: string;
    };
  };
}

type Paths = PropPath<Nested>;
// 'user' | 'user.profile' | 'user.profile.name'

// CSS properties
type CSSProperty = 'color' | 'background' | 'font-size';
type CSSValue = string;
type CSSProperties = Record<CSSProperty, CSSValue>;

// Data attributes
type DataAttribute = `data-${string}`;
type HTMLAttributes = {
  [K in DataAttribute]: string;
};
```

## Branded Types

### Basic Branding

```typescript
// Nominal typing using branding
type Brand<K, T> = K & { __brand: T };

type UserId = Brand<string, 'UserId'>;
type Email = Brand<string, 'Email'>;
type UUID = Brand<string, 'UUID'>;

function createUserId(id: string): UserId {
  // Validation logic here
  return id as UserId;
}

function fetchUser(id: UserId): User {
  // Implementation
}

const id = createUserId('user-123');
fetchUser(id); // OK

const rawString = 'user-456';
// fetchUser(rawString); // Error: string is not UserId

// Multiple brands
type PositiveNumber = Brand<number, 'Positive'>;
type Integer = Brand<number, 'Integer'>;
type PositiveInteger = PositiveNumber & Integer;

function createPositive(n: number): PositiveNumber {
  if (n <= 0) throw new Error('Must be positive');
  return n as PositiveNumber;
}

function createInteger(n: number): Integer {
  if (!Number.isInteger(n)) throw new Error('Must be integer');
  return n as Integer;
}

function createPositiveInteger(n: number): PositiveInteger {
  if (n <= 0 || !Number.isInteger(n)) {
    throw new Error('Must be positive integer');
  }
  return n as PositiveInteger;
}
```

### Validated Types

```typescript
// URL validation
type ValidatedURL = Brand<string, 'ValidatedURL'>;

function createURL(url: string): ValidatedURL {
  try {
    new URL(url);
    return url as ValidatedURL;
  } catch {
    throw new Error(`Invalid URL: ${url}`);
  }
}

// Email validation
type ValidatedEmail = Brand<string, 'ValidatedEmail'>;

function createEmail(email: string): ValidatedEmail {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new Error(`Invalid email: ${email}`);
  }
  return email as ValidatedEmail;
}

// Non-empty string
type NonEmptyString = Brand<string, 'NonEmpty'>;

function createNonEmpty(str: string): NonEmptyString {
  if (str.length === 0) {
    throw new Error('String cannot be empty');
  }
  return str as NonEmptyString;
}

// Date range
type FutureDate = Brand<Date, 'Future'>;
type PastDate = Brand<Date, 'Past'>;

function createFutureDate(date: Date): FutureDate {
  if (date <= new Date()) {
    throw new Error('Date must be in the future');
  }
  return date as FutureDate;
}
```

## Advanced Patterns

### Builder Pattern with Types

```typescript
class QueryBuilder<T extends object, Selected = never> {
  private selectFields: string[] = [];
  private whereConditions: Array<[string, any]> = [];

  select<K extends keyof T>(
    ...fields: K[]
  ): QueryBuilder<T, Selected | K> {
    this.selectFields.push(...(fields as string[]));
    return this as any;
  }

  where(field: keyof T, value: any): QueryBuilder<T, Selected> {
    this.whereConditions.push([field as string, value]);
    return this;
  }

  execute(): Pick<T, Selected & keyof T>[] {
    // Implementation
    return [] as any;
  }
}

// Usage
const results = new QueryBuilder<User>()
  .select('id', 'name')
  .where('age', 30)
  .execute();
// Type: Pick<User, 'id' | 'name'>[]
```

### State Machine Types

```typescript
type State = 'idle' | 'loading' | 'success' | 'error';

type Event =
  | { type: 'FETCH' }
  | { type: 'SUCCESS'; data: User }
  | { type: 'ERROR'; error: string }
  | { type: 'RESET' };

type StateValue<S extends State> =
  S extends 'idle' ? { state: 'idle' }
  : S extends 'loading' ? { state: 'loading' }
  : S extends 'success' ? { state: 'success'; data: User }
  : S extends 'error' ? { state: 'error'; error: string }
  : never;

type MachineState = StateValue<State>;

function transition(current: MachineState, event: Event): MachineState {
  switch (current.state) {
    case 'idle':
      if (event.type === 'FETCH') {
        return { state: 'loading' };
      }
      break;
    case 'loading':
      if (event.type === 'SUCCESS') {
        return { state: 'success', data: event.data };
      }
      if (event.type === 'ERROR') {
        return { state: 'error', error: event.error };
      }
      break;
    case 'success':
    case 'error':
      if (event.type === 'RESET') {
        return { state: 'idle' };
      }
      break;
  }
  return current;
}
```

### Phantom Types

```typescript
// Phantom types for compile-time safety
type UnvalidatedInput<T> = T & { __validation: 'unvalidated' };
type ValidatedInput<T> = T & { __validation: 'validated' };

type UserInput = {
  email: string;
  password: string;
};

function validateUserInput(
  input: UnvalidatedInput<UserInput>
): ValidatedInput<UserInput> {
  // Validation logic
  return input as ValidatedInput<UserInput>;
}

function createUser(input: ValidatedInput<UserInput>): User {
  // Only accepts validated input
  return {} as User;
}

const rawInput = { email: 'test@test.com', password: '123' } as UnvalidatedInput<UserInput>;
// createUser(rawInput); // Error: must be validated
const validated = validateUserInput(rawInput);
createUser(validated); // OK
```
