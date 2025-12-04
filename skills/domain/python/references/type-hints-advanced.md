# Advanced Type Hints

Deep dive into Python's type system for complex scenarios.

## Generic Types

```python
from typing import TypeVar, Generic, Protocol

T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

# Basic generic class
class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        if not self._items:
            raise IndexError("pop from empty stack")
        return self._items.pop()

    def peek(self) -> T | None:
        return self._items[-1] if self._items else None

# Multiple type parameters
class Mapping(Generic[K, V]):
    def __init__(self) -> None:
        self._data: dict[K, V] = {}

    def get(self, key: K) -> V | None:
        return self._data.get(key)

    def set(self, key: K, value: V) -> None:
        self._data[key] = value

# Bounded type variables
from numbers import Real

T_Number = TypeVar('T_Number', bound=Real)

class Calculator(Generic[T_Number]):
    def add(self, a: T_Number, b: T_Number) -> T_Number:
        return a + b  # type: ignore

    def multiply(self, a: T_Number, b: T_Number) -> T_Number:
        return a * b  # type: ignore

# Constrained type variables (must be one of specified types)
T_StringOrBytes = TypeVar('T_StringOrBytes', str, bytes)

def first_char(s: T_StringOrBytes) -> T_StringOrBytes:
    if not s:
        return s
    return s[:1]

# Variance (covariance, contravariance, invariance)
T_co = TypeVar('T_co', covariant=True)  # Producer
T_contra = TypeVar('T_contra', contravariant=True)  # Consumer

class Producer(Generic[T_co]):
    """Can return T_co or any subtype."""
    def produce(self) -> T_co:
        ...

class Consumer(Generic[T_contra]):
    """Can accept T_contra or any supertype."""
    def consume(self, item: T_contra) -> None:
        ...
```

## Protocols (Structural Subtyping)

```python
from typing import Protocol, runtime_checkable

# Basic protocol
class Closable(Protocol):
    def close(self) -> None: ...

def cleanup(resource: Closable) -> None:
    """Works with anything that has a close() method."""
    resource.close()

# Any object with close() works
class File:
    def close(self) -> None:
        print("File closed")

class Connection:
    def close(self) -> None:
        print("Connection closed")

cleanup(File())  # OK
cleanup(Connection())  # OK

# Protocol with properties
class Sized(Protocol):
    @property
    def size(self) -> int: ...

def print_size(obj: Sized) -> None:
    print(f"Size: {obj.size}")

# Protocol with generic
from typing import Iterator

class SupportsIter(Protocol[T]):
    def __iter__(self) -> Iterator[T]: ...

def process_items(container: SupportsIter[str]) -> None:
    for item in container:
        print(item.upper())

# Runtime checkable protocols
@runtime_checkable
class Drawable(Protocol):
    def draw(self) -> None: ...

class Circle:
    def draw(self) -> None:
        print("Drawing circle")

c = Circle()
if isinstance(c, Drawable):  # Works at runtime!
    c.draw()

# Complex protocol example
class SupportsComparison(Protocol):
    def __lt__(self, other: 'SupportsComparison') -> bool: ...
    def __le__(self, other: 'SupportsComparison') -> bool: ...
    def __gt__(self, other: 'SupportsComparison') -> bool: ...
    def __ge__(self, other: 'SupportsComparison') -> bool: ...

def find_max(items: list[SupportsComparison]) -> SupportsComparison:
    if not items:
        raise ValueError("Empty list")
    return max(items)
```

## Function Overloading

```python
from typing import overload, Literal

# Basic overload
@overload
def process(data: str) -> str: ...

@overload
def process(data: int) -> int: ...

@overload
def process(data: list[str]) -> list[str]: ...

def process(data: str | int | list[str]) -> str | int | list[str]:
    """Implementation handles all cases."""
    if isinstance(data, str):
        return data.upper()
    elif isinstance(data, int):
        return data * 2
    else:
        return [item.upper() for item in data]

# Overload with Literal types
@overload
def get_config(key: Literal["host"]) -> str: ...

@overload
def get_config(key: Literal["port"]) -> int: ...

@overload
def get_config(key: Literal["debug"]) -> bool: ...

def get_config(key: str) -> str | int | bool:
    config = {"host": "localhost", "port": 8000, "debug": True}
    return config[key]

# Type checker knows the return type!
host: str = get_config("host")  # OK
port: int = get_config("port")  # OK
debug: bool = get_config("debug")  # OK

# Overload with optional parameters
@overload
def fetch_data(url: str) -> dict: ...

@overload
def fetch_data(url: str, timeout: int) -> dict: ...

@overload
def fetch_data(url: str, timeout: int, headers: dict[str, str]) -> dict: ...

def fetch_data(
    url: str,
    timeout: int | None = None,
    headers: dict[str, str] | None = None
) -> dict:
    # Implementation
    ...
```

## Type Aliases and NewType

```python
from typing import NewType, TypeAlias

# Type aliases (3.10+ style)
type UserID = int
type Config = dict[str, str | int | bool]
type JSONValue = str | int | float | bool | None | list['JSONValue'] | dict[str, 'JSONValue']

# Old style (pre-3.10)
UserID: TypeAlias = int
Config: TypeAlias = dict[str, str | int | bool]

# NewType creates distinct types (runtime identity check)
UserId = NewType('UserId', int)
ProductId = NewType('ProductId', int)

def get_user(user_id: UserId) -> dict:
    return {"id": user_id, "name": "Alice"}

def get_product(product_id: ProductId) -> dict:
    return {"id": product_id, "name": "Widget"}

user_id = UserId(42)
product_id = ProductId(99)

get_user(user_id)  # OK
get_user(product_id)  # Type error! ProductId is not UserId
get_user(42)  # Type error! int is not UserId

# Complex type aliases
type Headers = dict[str, str]
type QueryParams = dict[str, str | int | bool]
type HTTPResponse = tuple[int, Headers, str]

def make_request(
    url: str,
    params: QueryParams | None = None
) -> HTTPResponse:
    ...

# Recursive type aliases
type TreeNode[T] = tuple[T, list['TreeNode[T]']]

def traverse(node: TreeNode[int]) -> None:
    value, children = node
    print(value)
    for child in children:
        traverse(child)
```

## Advanced Union and Intersection Types

```python
from typing import Union, Literal, get_args, get_origin

# Discriminated unions (tagged unions)
from dataclasses import dataclass

@dataclass
class Success:
    type: Literal["success"]
    value: str

@dataclass
class Error:
    type: Literal["error"]
    message: str

type Result = Success | Error

def process_result(result: Result) -> None:
    match result.type:
        case "success":
            # Type checker knows result is Success here
            print(f"Value: {result.value}")
        case "error":
            # Type checker knows result is Error here
            print(f"Error: {result.message}")

# Never type (functions that never return)
from typing import Never, NoReturn, assert_never

def assert_never(value: Never) -> Never:
    """Helper for exhaustiveness checking."""
    raise AssertionError(f"Unhandled value: {value}")

def handle_status(status: Literal["pending", "active", "done"]) -> str:
    match status:
        case "pending":
            return "Waiting"
        case "active":
            return "Processing"
        case "done":
            return "Complete"
        case _:
            assert_never(status)  # Ensures all cases handled

# Type guards
from typing import TypeGuard

def is_string_list(val: list[object]) -> TypeGuard[list[str]]:
    """Type guard that narrows type."""
    return all(isinstance(x, str) for x in val)

def process(items: list[object]) -> None:
    if is_string_list(items):
        # Type checker knows items is list[str] here
        for item in items:
            print(item.upper())  # OK, item is str

# Type narrowing with isinstance
def process_value(value: str | int | None) -> str:
    if value is None:
        return "none"
    elif isinstance(value, str):
        # Type checker knows value is str here
        return value.upper()
    else:
        # Type checker knows value is int here
        return str(value * 2)
```

## Callable Types

```python
from typing import Callable, ParamSpec, Concatenate
from collections.abc import Callable as ABCCallable

# Basic callable
def apply(func: Callable[[int], str], value: int) -> str:
    return func(value)

result = apply(str, 42)  # OK

# Multiple parameters
def map_pair(
    func: Callable[[int, int], int],
    a: int,
    b: int
) -> int:
    return func(a, b)

# Variable arguments
def retry(
    func: Callable[..., T],
    *args: object,
    **kwargs: object
) -> T:
    return func(*args, **kwargs)

# ParamSpec for preserving signature
P = ParamSpec('P')
T = TypeVar('T')

def decorator(func: Callable[P, T]) -> Callable[P, T]:
    """Decorator that preserves function signature."""
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        print("Before")
        result = func(*args, **kwargs)
        print("After")
        return result
    return wrapper

@decorator
def add(a: int, b: int) -> int:
    return a + b

# Type checker knows signature is preserved
result: int = add(1, 2)  # OK
add("x", "y")  # Type error

# Concatenate for adding parameters
def with_logging(
    func: Callable[Concatenate[str, P], T]
) -> Callable[P, T]:
    """Decorator that removes first 'name' parameter."""
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        return func("logged", *args, **kwargs)
    return wrapper
```

## TypedDict and Required/NotRequired

```python
from typing import TypedDict, Required, NotRequired

# Basic TypedDict
class User(TypedDict):
    name: str
    email: str
    age: int

user: User = {
    "name": "Alice",
    "email": "alice@example.com",
    "age": 30
}

# Optional keys (old style)
class UserOptional(TypedDict, total=False):
    name: str
    email: str
    age: int  # All fields optional

# Mixed required/optional (3.11+)
class UserMixed(TypedDict):
    name: str  # Required
    email: str  # Required
    age: NotRequired[int]  # Optional
    nickname: NotRequired[str]  # Optional

# Inheritance
class BaseUser(TypedDict):
    id: int
    name: str

class AdminUser(BaseUser):
    permissions: list[str]
    role: str

admin: AdminUser = {
    "id": 1,
    "name": "Admin",
    "permissions": ["read", "write"],
    "role": "superuser"
}

# Generic TypedDict
class Response(TypedDict, Generic[T]):
    status: int
    data: T
    message: str

success: Response[list[str]] = {
    "status": 200,
    "data": ["item1", "item2"],
    "message": "OK"
}
```

## Self Type

```python
from typing import Self

# Method returning instance of same class
class Builder:
    def __init__(self) -> None:
        self._config: dict[str, str] = {}

    def set_option(self, key: str, value: str) -> Self:
        """Returns self for chaining."""
        self._config[key] = value
        return self

    def build(self) -> dict[str, str]:
        return self._config.copy()

# Works with subclasses
class AdvancedBuilder(Builder):
    def set_advanced(self, key: str) -> Self:
        self._config[f"advanced_{key}"] = "true"
        return self

# Type checker knows chain returns AdvancedBuilder
result = AdvancedBuilder().set_option("x", "y").set_advanced("z").build()

# Without Self, would need complex overloads
class OldStyle:
    @overload
    def method(self: 'OldStyle') -> 'OldStyle': ...

    @overload
    def method(self: T) -> T: ...

    def method(self):
        return self
```

## Unpack and TypeVarTuple

```python
from typing import Unpack, TypeVarTuple

# Unpacking TypedDict parameters
class MovieDetails(TypedDict):
    title: str
    year: int
    director: str

def create_movie(**kwargs: Unpack[MovieDetails]) -> dict:
    return dict(kwargs)

# Type safe!
create_movie(title="Inception", year=2010, director="Nolan")  # OK
create_movie(title="Inception")  # Error: missing year, director

# Variable length tuple types
Ts = TypeVarTuple('Ts')

class Array(Generic[Unpack[Ts]]):
    def __init__(self, *args: Unpack[Ts]) -> None:
        self._items = args

    def get(self) -> tuple[Unpack[Ts]]:
        return self._items

# Typed tuples of different lengths
arr1: Array[int] = Array(1)
arr2: Array[int, str] = Array(1, "hello")
arr3: Array[int, str, bool] = Array(1, "hello", True)

# Generic function with variable args
def zip_strict(*args: Unpack[Ts]) -> list[tuple[Unpack[Ts]]]:
    ...
```

## Type Narrowing Patterns

```python
from typing import TypeIs, assert_type

# TypeIs (3.13+, more powerful than TypeGuard)
def is_list_of_str(val: list[object]) -> TypeIs[list[str]]:
    """Not just for narrowing, but also for isinstance checks."""
    return isinstance(val, list) and all(isinstance(x, str) for x in val)

# assert_type for testing type inference
def process(value: int | str) -> None:
    if isinstance(value, int):
        assert_type(value, int)  # Verifies type checker understands
        print(value + 1)
    else:
        assert_type(value, str)
        print(value.upper())

# Pattern matching for narrowing (3.10+)
def handle_value(val: int | str | list[int]) -> str:
    match val:
        case int(x):
            assert_type(x, int)
            return f"int: {x}"
        case str(s):
            assert_type(s, str)
            return f"str: {s}"
        case list(items):
            assert_type(items, list[int])
            return f"list: {sum(items)}"
        case _:
            assert_never(val)

# Using hasattr for narrowing
class Dog:
    def bark(self) -> None: ...

class Cat:
    def meow(self) -> None: ...

def make_sound(animal: Dog | Cat) -> None:
    if hasattr(animal, "bark"):
        # Limited narrowing, Protocol is better
        animal.bark()  # type: ignore
    else:
        animal.meow()  # type: ignore

# Better with Protocol
class CanBark(Protocol):
    def bark(self) -> None: ...

class CanMeow(Protocol):
    def meow(self) -> None: ...

def make_sound_safe(animal: CanBark | CanMeow) -> None:
    if isinstance(animal, CanBark):
        animal.bark()  # Properly narrowed
    else:
        animal.meow()  # Properly narrowed
```

## Final and Annotated

```python
from typing import Final, Annotated, get_type_hints

# Final variables (cannot be reassigned)
MAX_SIZE: Final = 100
MAX_SIZE = 200  # Type error

# Final in classes
class Config:
    BASE_URL: Final[str] = "https://api.example.com"

    def __init__(self) -> None:
        self.BASE_URL = "other"  # Type error

# Final methods (cannot be overridden)
class Base:
    @final
    def important_method(self) -> None:
        ...

class Derived(Base):
    def important_method(self) -> None:  # Type error
        ...

# Annotated for metadata
UserId = Annotated[int, "User identifier", "Positive integer"]
Timestamp = Annotated[int, "Unix timestamp in seconds"]

def get_user(user_id: UserId) -> dict:
    # Type checker sees UserId as int, runtime tools see metadata
    ...

# Runtime metadata access
hints = get_type_hints(get_user, include_extras=True)
# hints["user_id"] is Annotated[int, "User identifier", "Positive integer"]

# Use with Pydantic for validation
from pydantic import BaseModel, Field

class User(BaseModel):
    id: Annotated[int, Field(gt=0, description="User ID")]
    email: Annotated[str, Field(pattern=r"^.+@.+$")]
```

## Tips for Type Checking

1. **Start strict**: Enable `strict = true` in mypy config
2. **Use protocols for duck typing**: More flexible than inheritance
3. **Leverage Union narrowing**: Use isinstance, match for type narrowing
4. **Avoid Any**: Use Unknown or specific types
5. **Use NewType for domain types**: Prevents mixing IDs, etc.
6. **Type overloads sparingly**: Consider Protocols or Union instead
7. **Document with type aliases**: Makes complex types readable
8. **Use reveal_type() for debugging**: Shows what type checker infers
9. **Test type stubs**: Use `stubtest` for accuracy
10. **Keep runtime overhead low**: Types are compile-time only

## Common Type Checking Issues

```python
# Issue: Incompatible return type
def get_value() -> str:
    return None  # Error: None is not str

# Fix: Use Optional
def get_value() -> str | None:
    return None  # OK

# Issue: List invariance
def add_animal(animals: list[Animal]) -> None:
    animals.append(Animal())

dogs: list[Dog] = []
add_animal(dogs)  # Error: list is invariant

# Fix: Use Sequence (covariant)
def add_animal(animals: Sequence[Animal]) -> None:
    for animal in animals:  # Can only read
        print(animal)

add_animal(dogs)  # OK

# Issue: Missing return
def process() -> int:
    x = 5
    # Forgot to return

# Fix: Add explicit return
def process() -> int:
    x = 5
    return x

# Issue: Unreachable code
def check(value: int) -> str:
    if value > 0:
        return "positive"
    else:
        return "non-positive"
    print("unreachable")  # Warning

# Fix: Remove unreachable code or restructure
```
