# Data Modeling: Dataclasses and Pydantic

Complete guide to Python data structures and validation.

## Dataclasses

### Basic Usage

```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import ClassVar

@dataclass
class User:
    """Basic user model."""
    id: int
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)

# Create instance
user = User(id=1, name="Alice", email="alice@example.com")
print(user.name)  # Alice

# Auto-generated methods
print(user)  # User(id=1, name='Alice', ...)
user2 = User(id=1, name="Alice", email="alice@example.com")
print(user == user2)  # True
```

### Field Options

```python
from dataclasses import dataclass, field, Field
from typing import Any

@dataclass
class Product:
    # Required field
    name: str

    # Optional with default
    price: float = 0.0

    # Default factory (for mutable defaults)
    tags: list[str] = field(default_factory=list)

    # Field with metadata
    quantity: int = field(default=0, metadata={"unit": "items"})

    # Exclude from repr
    internal_id: str = field(repr=False, default="")

    # Exclude from comparison
    last_modified: datetime = field(compare=False, default_factory=datetime.now)

    # Exclude from __init__
    computed: str = field(init=False)

    # Class variable (not an instance field)
    category: ClassVar[str] = "general"

    def __post_init__(self):
        """Called after __init__."""
        self.computed = f"{self.name}_{self.internal_id}"
```

### Frozen (Immutable) Dataclasses

```python
@dataclass(frozen=True)
class Point:
    """Immutable point."""
    x: float
    y: float

point = Point(1.0, 2.0)
# point.x = 3.0  # Error: cannot assign to field

# Can be used as dict keys
points = {Point(0, 0): "origin", Point(1, 1): "diagonal"}
```

### Ordering

```python
@dataclass(order=True)
class Person:
    """Comparable person by age."""
    sort_index: int = field(init=False, repr=False)
    name: str
    age: int

    def __post_init__(self):
        self.sort_index = self.age

people = [
    Person("Alice", 30),
    Person("Bob", 25),
    Person("Charlie", 35)
]
print(sorted(people))  # Sorted by age
```

### Inheritance

```python
@dataclass
class Base:
    id: int
    created_at: datetime = field(default_factory=datetime.now)

@dataclass
class User(Base):
    """Inherits id and created_at."""
    name: str
    email: str

user = User(id=1, name="Alice", email="alice@example.com")
print(user.created_at)  # Inherited field
```

### Advanced Patterns

```python
from dataclasses import dataclass, field, asdict, astuple, replace
from typing import Any, Optional

@dataclass
class Config:
    """Configuration with validation."""
    host: str
    port: int
    timeout: float = 30.0
    options: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        """Validate after initialization."""
        if self.port < 1 or self.port > 65535:
            raise ValueError(f"Invalid port: {self.port}")
        if self.timeout < 0:
            raise ValueError("Timeout must be positive")

# Convert to dict
config = Config("localhost", 8000)
config_dict = asdict(config)
print(config_dict)  # {'host': 'localhost', 'port': 8000, ...}

# Convert to tuple
config_tuple = astuple(config)
print(config_tuple)  # ('localhost', 8000, 30.0, {})

# Create modified copy (immutability pattern)
config2 = replace(config, port=9000)
print(config.port)   # 8000 (unchanged)
print(config2.port)  # 9000 (new instance)
```

### Slots for Memory Optimization

```python
@dataclass(slots=True)  # Python 3.10+
class OptimizedUser:
    """Uses __slots__ for memory efficiency."""
    id: int
    name: str
    email: str

# 40% less memory per instance
# Faster attribute access
# Cannot add new attributes dynamically
```

### KW-Only and Positional-Only

```python
@dataclass(kw_only=True)  # Python 3.10+
class KWOnlyUser:
    """All fields must be passed as keyword arguments."""
    id: int
    name: str

# user = KWOnlyUser(1, "Alice")  # Error
user = KWOnlyUser(id=1, name="Alice")  # OK

# Mixed positional and keyword-only
@dataclass
class MixedUser:
    id: int  # Positional
    name: str = field(kw_only=True)  # Keyword-only

user = MixedUser(1, name="Alice")  # OK
# user = MixedUser(1, "Alice")  # Error
```

## Pydantic V2

### Basic Models

```python
from pydantic import BaseModel, Field, field_validator, model_validator
from typing import Annotated

class User(BaseModel):
    """User model with validation."""
    id: int
    name: str
    email: str
    age: int = Field(ge=0, le=150)  # Validation constraints

# Automatic validation
user = User(id=1, name="Alice", email="alice@example.com", age=30)

# Validation error
try:
    invalid_user = User(id="not_int", name="Bob", email="bob@", age=-5)
except ValidationError as e:
    print(e.json())  # Detailed error messages
```

### Field Validation

```python
from pydantic import (
    BaseModel,
    Field,
    EmailStr,
    HttpUrl,
    conint,
    constr,
    confloat,
    conlist,
)
from typing import Annotated

class Product(BaseModel):
    # String constraints
    name: Annotated[str, Field(min_length=1, max_length=100)]
    sku: constr(pattern=r"^[A-Z]{3}-\d{4}$")  # Regex pattern

    # Numeric constraints
    price: Annotated[float, Field(gt=0, le=1000000)]
    quantity: conint(ge=0)
    discount: confloat(ge=0.0, le=1.0)

    # Built-in types with validation
    website: HttpUrl
    contact_email: EmailStr

    # Collection constraints
    tags: conlist(str, min_length=1, max_length=10)
    dimensions: conlist(float, min_length=3, max_length=3)

    # Multiple of
    package_size: Annotated[int, Field(multiple_of=6)]
```

### Custom Validators

```python
from pydantic import BaseModel, field_validator, model_validator

class User(BaseModel):
    username: str
    email: str
    password: str
    password_confirm: str

    @field_validator("username")
    @classmethod
    def username_alphanumeric(cls, v: str) -> str:
        """Validate username is alphanumeric."""
        if not v.isalnum():
            raise ValueError("Username must be alphanumeric")
        return v

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        """Normalize email to lowercase."""
        return v.lower().strip()

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        """Validate password strength."""
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain uppercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain digit")
        return v

    @model_validator(mode="after")
    def passwords_match(self) -> "User":
        """Validate passwords match (uses entire model)."""
        if self.password != self.password_confirm:
            raise ValueError("Passwords do not match")
        return self
```

### Computed Fields

```python
from pydantic import BaseModel, computed_field

class Person(BaseModel):
    first_name: str
    last_name: str
    birth_year: int

    @computed_field
    @property
    def full_name(self) -> str:
        """Computed field included in serialization."""
        return f"{self.first_name} {self.last_name}"

    @computed_field
    @property
    def age(self) -> int:
        """Current age."""
        from datetime import datetime
        return datetime.now().year - self.birth_year

person = Person(first_name="Alice", last_name="Smith", birth_year=1990)
print(person.full_name)  # Alice Smith
print(person.model_dump())  # Includes computed fields
```

### Serialization

```python
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Any

class Event(BaseModel):
    model_config = ConfigDict(
        # Serialization aliases
        populate_by_name=True,
        # Allow extra fields
        extra="allow",
        # Validate on assignment
        validate_assignment=True,
    )

    id: int
    name: str
    timestamp: datetime = Field(alias="ts")  # Accept 'ts' as input
    metadata: dict[str, Any] = Field(default_factory=dict, exclude=True)  # Exclude from serialization

# Dictionary serialization
event = Event(id=1, name="Test", ts=datetime.now())

# Standard serialization
print(event.model_dump())  # Python dict

# JSON serialization
print(event.model_dump_json())  # JSON string

# With aliases
print(event.model_dump(by_alias=True))  # Uses 'ts' instead of 'timestamp'

# Exclude fields
print(event.model_dump(exclude={"id"}))

# Include only certain fields
print(event.model_dump(include={"name", "timestamp"}))

# Exclude unset fields
print(event.model_dump(exclude_unset=True))

# Exclude None values
print(event.model_dump(exclude_none=True))
```

### Model Configuration

```python
from pydantic import BaseModel, ConfigDict, Field

class StrictModel(BaseModel):
    model_config = ConfigDict(
        # Strict type validation (no coercion)
        strict=True,

        # Immutability
        frozen=True,

        # Validation behavior
        validate_assignment=True,
        validate_default=True,
        validate_return=True,

        # Field behavior
        extra="forbid",  # "allow", "forbid", "ignore"
        populate_by_name=True,  # Accept both alias and name

        # Serialization
        use_enum_values=True,
        arbitrary_types_allowed=False,

        # JSON schema
        json_schema_extra={
            "examples": [
                {"id": 1, "name": "Example"}
            ]
        },

        # String handling
        str_strip_whitespace=True,
        str_to_lower=False,
        str_to_upper=False,
        str_min_length=0,
        str_max_length=None,
    )

    id: int
    name: str
```

### Nested Models

```python
from pydantic import BaseModel
from typing import Optional

class Address(BaseModel):
    street: str
    city: str
    country: str
    postal_code: str

class Company(BaseModel):
    name: str
    address: Address

class Employee(BaseModel):
    id: int
    name: str
    email: str
    company: Company
    home_address: Optional[Address] = None

# Create nested structure
employee = Employee(
    id=1,
    name="Alice",
    email="alice@example.com",
    company=Company(
        name="Acme Corp",
        address=Address(
            street="123 Main St",
            city="Springfield",
            country="USA",
            postal_code="12345"
        )
    )
)

# Access nested fields
print(employee.company.address.city)  # Springfield

# Serialize nested
data = employee.model_dump()
# Fully nested dict structure
```

### Generic Models

```python
from pydantic import BaseModel
from typing import Generic, TypeVar

T = TypeVar('T')

class Response(BaseModel, Generic[T]):
    """Generic API response."""
    status: int
    message: str
    data: T

class UserData(BaseModel):
    id: int
    name: str

# Type-safe responses
user_response = Response[UserData](
    status=200,
    message="Success",
    data=UserData(id=1, name="Alice")
)

list_response = Response[list[int]](
    status=200,
    message="Success",
    data=[1, 2, 3, 4, 5]
)
```

### Settings Management

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    """Application settings from environment."""
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="APP_",  # APP_DATABASE_URL
        case_sensitive=False,
    )

    # Database
    database_url: str
    database_pool_size: int = 10

    # API
    api_key: str
    api_timeout: float = 30.0

    # Feature flags
    debug: bool = False
    testing: bool = False

    # Nested config
    class RedisConfig(BaseSettings):
        host: str = "localhost"
        port: int = 6379
        db: int = 0

    redis: RedisConfig = RedisConfig()

@lru_cache
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()

# Usage
settings = get_settings()
print(settings.database_url)
```

### Advanced Validation Patterns

```python
from pydantic import BaseModel, field_validator, model_validator
from typing import Any

class PaymentRequest(BaseModel):
    amount: float
    currency: str
    payment_method: str
    card_number: str | None = None
    bank_account: str | None = None

    @model_validator(mode="before")
    @classmethod
    def check_payment_details(cls, data: Any) -> Any:
        """Validate payment method has required details."""
        if isinstance(data, dict):
            method = data.get("payment_method")
            if method == "card" and not data.get("card_number"):
                raise ValueError("Card payment requires card_number")
            if method == "bank" and not data.get("bank_account"):
                raise ValueError("Bank payment requires bank_account")
        return data

    @field_validator("amount")
    @classmethod
    def amount_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("Amount must be positive")
        return v

    @field_validator("currency")
    @classmethod
    def currency_uppercase(cls, v: str) -> str:
        return v.upper()

    @field_validator("card_number")
    @classmethod
    def validate_card(cls, v: str | None) -> str | None:
        if v is None:
            return v
        # Remove spaces
        v = v.replace(" ", "")
        if not v.isdigit() or len(v) not in [13, 15, 16, 19]:
            raise ValueError("Invalid card number")
        return v
```

### Custom Types

```python
from pydantic import BaseModel, field_validator, GetCoreSchemaHandler
from pydantic_core import core_schema
from typing import Any

class EvenInt:
    """Custom type that only accepts even integers."""

    @classmethod
    def __get_pydantic_core_schema__(
        cls,
        source: type[Any],
        handler: GetCoreSchemaHandler
    ) -> core_schema.CoreSchema:
        return core_schema.with_info_plain_validator_function(
            cls._validate,
            serialization=core_schema.plain_serializer_function_ser_schema(
                lambda x: x
            ),
        )

    @classmethod
    def _validate(cls, value: Any, _: Any) -> int:
        if not isinstance(value, int):
            raise ValueError("Must be an integer")
        if value % 2 != 0:
            raise ValueError("Must be even")
        return value

class Model(BaseModel):
    even_number: EvenInt

# Usage
model = Model(even_number=4)  # OK
# model = Model(even_number=3)  # Error: Must be even
```

### JSON Schema Generation

```python
from pydantic import BaseModel, Field

class User(BaseModel):
    """User model for API."""
    id: int = Field(..., description="Unique user identifier")
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., description="User email address")
    age: int = Field(..., ge=0, le=150, description="User age")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "id": 1,
                    "name": "Alice Smith",
                    "email": "alice@example.com",
                    "age": 30
                }
            ]
        }
    }

# Generate JSON schema
schema = User.model_json_schema()
print(json.dumps(schema, indent=2))
```

### Performance Tips

```python
from pydantic import BaseModel, ConfigDict, Field

# 1. Use frozen models (immutable)
class FrozenUser(BaseModel):
    model_config = ConfigDict(frozen=True)
    id: int
    name: str

# 2. Disable validation for trusted data
data = {"id": 1, "name": "Alice"}
user = User.model_validate(data)  # With validation
user_fast = User.model_construct(**data)  # Without validation (faster)

# 3. Reuse models instead of recreating
users = [User.model_validate(d) for d in data_list]

# 4. Use strict mode for no coercion
class StrictModel(BaseModel):
    model_config = ConfigDict(strict=True)
    id: int  # Must be int, not string "1"

# 5. Defer validation
class DeferredModel(BaseModel):
    model_config = ConfigDict(validate_assignment=False)
    # Validate only on creation, not on updates
```

## Comparison: Dataclasses vs Pydantic

```python
# Dataclasses: Lightweight, standard library
@dataclass
class DataclassUser:
    id: int
    name: str
    email: str

    def __post_init__(self):
        # Manual validation
        if not self.email:
            raise ValueError("Email required")

# Pydantic: Rich validation, serialization
class PydanticUser(BaseModel):
    id: int
    name: str
    email: EmailStr  # Automatic validation

# When to use dataclasses:
# - Simple data containers
# - No external data (already validated)
# - Performance critical (slightly faster)
# - Standard library only

# When to use Pydantic:
# - API request/response validation
# - Configuration from environment
# - Data from external sources
# - Need JSON schema
# - Complex validation logic
```

## Best Practices

1. **Use Pydantic for external data**: APIs, configs, user input
2. **Use dataclasses for internal data**: Within application boundary
3. **Validate early**: At system boundaries
4. **Frozen models for immutability**: Safer, hashable
5. **Custom validators for complex logic**: Keep models clean
6. **Settings from environment**: Use pydantic-settings
7. **Type hints everywhere**: Enables validation
8. **Computed fields for derived data**: Don't store redundant info
9. **Use aliases for API compatibility**: Snake_case ↔ camelCase
10. **Generate JSON schemas**: For documentation and validation
