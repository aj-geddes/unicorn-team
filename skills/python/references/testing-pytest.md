# Pytest Deep Dive

Comprehensive testing patterns with pytest.

## Fixture Patterns

```python
import pytest
from pathlib import Path

# Basic fixture
@pytest.fixture
def sample_data() -> dict:
    """Provide sample data for tests."""
    return {"name": "Alice", "age": 30}

def test_user_name(sample_data):
    assert sample_data["name"] == "Alice"

# Fixture with setup/teardown
@pytest.fixture
def temp_database():
    """Create and cleanup database."""
    db = create_database()
    yield db
    db.drop()  # Cleanup

# Fixture scopes: function (default), class, module, package, session
@pytest.fixture(scope="session")
def app_config():
    """Load config once per test session."""
    return load_config("test_config.yaml")

@pytest.fixture(scope="module")
def database_connection():
    """Share connection across module."""
    conn = connect_to_db()
    yield conn
    conn.close()

@pytest.fixture(scope="function")
def clean_database(database_connection):
    """Clean database before each test."""
    database_connection.execute("TRUNCATE TABLE users")
    yield database_connection

# Fixture factories (parameterized fixtures)
@pytest.fixture
def user_factory():
    """Factory for creating test users."""
    def _create_user(name: str = "Alice", email: str = None):
        if email is None:
            email = f"{name.lower()}@example.com"
        return {"name": name, "email": email}
    return _create_user

def test_multiple_users(user_factory):
    alice = user_factory("Alice")
    bob = user_factory("Bob")
    assert alice["name"] != bob["name"]

# Fixture dependency chain
@pytest.fixture
def database():
    return Database()

@pytest.fixture
def user_repository(database):
    return UserRepository(database)

@pytest.fixture
def user_service(user_repository):
    return UserService(user_repository)

def test_user_service(user_service):
    result = user_service.create_user("Alice")
    assert result is not None

# Autouse fixtures (run automatically)
@pytest.fixture(autouse=True)
def reset_state():
    """Reset global state before each test."""
    GlobalState.reset()
    yield
    # Cleanup if needed

# Request fixture for dynamic parameters
@pytest.fixture
def dynamic_fixture(request):
    """Access test context."""
    test_name = request.node.name
    print(f"Running test: {test_name}")
    return {"test_name": test_name}

# Built-in tmp_path fixture
def test_file_operations(tmp_path: Path):
    """tmp_path provides a temporary directory."""
    file_path = tmp_path / "test.txt"
    file_path.write_text("content")
    assert file_path.read_text() == "content"

# Built-in monkeypatch fixture
def test_environment_variable(monkeypatch):
    """Mock environment variables."""
    monkeypatch.setenv("API_KEY", "test_key")
    assert os.environ["API_KEY"] == "test_key"

def test_attribute_patch(monkeypatch):
    """Patch object attributes."""
    monkeypatch.setattr("module.CONSTANT", "mocked_value")
    assert module.CONSTANT == "mocked_value"

# Built-in capsys fixture
def test_stdout(capsys):
    """Capture stdout/stderr."""
    print("hello")
    captured = capsys.readouterr()
    assert captured.out == "hello\n"

# Built-in caplog fixture
def test_logging(caplog):
    """Capture log messages."""
    import logging
    logger = logging.getLogger("myapp")

    with caplog.at_level(logging.INFO):
        logger.info("test message")

    assert "test message" in caplog.text
    assert caplog.records[0].levelname == "INFO"
```

## Parametrization

```python
# Basic parametrize
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (2, 4),
    (3, 9),
    (-2, 4),
])
def test_square(input, expected):
    assert input ** 2 == expected

# Multiple parameters
@pytest.mark.parametrize("x,y,result", [
    (1, 2, 3),
    (5, 3, 8),
    (10, -5, 5),
])
def test_addition(x, y, result):
    assert x + y == result

# Named parameters with pytest.param
@pytest.mark.parametrize("value", [
    pytest.param(42, id="the_answer"),
    pytest.param(0, id="zero"),
    pytest.param(-1, id="negative", marks=pytest.mark.xfail),
])
def test_with_ids(value):
    assert value >= 0

# Indirect parametrization (through fixtures)
@pytest.fixture
def user(request):
    """Create user from parameter."""
    return create_user(request.param)

@pytest.mark.parametrize("user", ["alice", "bob"], indirect=True)
def test_user(user):
    assert user.name in ["alice", "bob"]

# Combining multiple parametrize decorators (cartesian product)
@pytest.mark.parametrize("x", [1, 2, 3])
@pytest.mark.parametrize("y", [10, 20])
def test_combinations(x, y):
    # Runs 6 tests: (1,10), (1,20), (2,10), (2,20), (3,10), (3,20)
    assert x + y > 0

# Parametrize fixtures
@pytest.fixture(params=["sqlite", "postgres", "mysql"])
def database_backend(request):
    """Test against multiple databases."""
    backend = create_database(request.param)
    yield backend
    backend.close()

def test_query(database_backend):
    """Runs once for each database backend."""
    result = database_backend.query("SELECT 1")
    assert result is not None

# Complex parametrization
test_cases = [
    pytest.param(
        {"name": "Alice", "age": 30},
        "valid",
        id="valid_user"
    ),
    pytest.param(
        {"name": "", "age": 30},
        "invalid_name",
        marks=pytest.mark.skip("Not implemented"),
        id="empty_name"
    ),
    pytest.param(
        {"name": "Bob", "age": -1},
        "invalid_age",
        id="negative_age"
    ),
]

@pytest.mark.parametrize("user_data,expected", test_cases)
def test_user_validation(user_data, expected):
    result = validate_user(user_data)
    assert result == expected
```

## Markers

```python
# Built-in markers
@pytest.mark.skip("Not implemented yet")
def test_future_feature():
    pass

@pytest.mark.skipif(sys.version_info < (3, 10), reason="Requires Python 3.10+")
def test_new_syntax():
    pass

@pytest.mark.xfail(reason="Known bug")
def test_known_issue():
    assert False  # Expected to fail

@pytest.mark.xfail(strict=True)
def test_strict_xfail():
    # Must fail, test fails if it passes
    assert False

# Custom markers (register in pytest.ini or pyproject.toml)
"""
[tool.pytest.ini_options]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
"""

@pytest.mark.slow
def test_slow_operation():
    time.sleep(5)

@pytest.mark.integration
def test_database_integration():
    pass

# Run specific markers
# pytest -m "slow"  # Run only slow tests
# pytest -m "not slow"  # Skip slow tests
# pytest -m "unit and not integration"  # Complex expressions

# Multiple markers
@pytest.mark.slow
@pytest.mark.integration
def test_complex():
    pass

# Conditional markers
@pytest.mark.skipif(not has_gpu(), reason="Requires GPU")
@pytest.mark.timeout(30)
def test_gpu_operation():
    pass

# Marker with parameters
@pytest.mark.timeout(10)
def test_with_timeout():
    pass

# Custom marker logic
def pytest_collection_modifyitems(config, items):
    """Skip integration tests if --integration flag not provided."""
    if not config.getoption("--integration"):
        skip_integration = pytest.mark.skip(reason="Need --integration flag")
        for item in items:
            if "integration" in item.keywords:
                item.add_marker(skip_integration)
```

## Mocking and Patching

```python
from unittest.mock import Mock, MagicMock, patch, call, ANY
import pytest

# Basic mock
def test_mock_object():
    mock_db = Mock()
    mock_db.get_user.return_value = {"id": 1, "name": "Alice"}

    result = process_user(mock_db, 1)

    mock_db.get_user.assert_called_once_with(1)
    assert result["name"] == "Alice"

# MagicMock (supports magic methods)
def test_magic_mock():
    mock_list = MagicMock()
    mock_list.__len__.return_value = 5

    assert len(mock_list) == 5

# Mock properties
def test_mock_property():
    mock_obj = Mock()
    type(mock_obj).property_name = PropertyMock(return_value="value")

    assert mock_obj.property_name == "value"

# Side effects (sequence of values)
def test_side_effect_sequence():
    mock_func = Mock(side_effect=[1, 2, 3])

    assert mock_func() == 1
    assert mock_func() == 2
    assert mock_func() == 3

# Side effect as exception
def test_side_effect_exception():
    mock_func = Mock(side_effect=ValueError("error"))

    with pytest.raises(ValueError):
        mock_func()

# Side effect as function
def test_side_effect_function():
    def double(x):
        return x * 2

    mock_func = Mock(side_effect=double)
    assert mock_func(5) == 10

# Patching functions
@patch("module.expensive_function")
def test_with_patch(mock_expensive):
    mock_expensive.return_value = "mocked"

    result = call_expensive_function()

    assert result == "mocked"
    mock_expensive.assert_called_once()

# Multiple patches
@patch("module.function_a")
@patch("module.function_b")
def test_multiple_patches(mock_b, mock_a):  # Note: reverse order
    mock_a.return_value = "a"
    mock_b.return_value = "b"

    result = combined_function()
    assert result == "ab"

# Context manager patching
def test_patch_context():
    with patch("module.function") as mock_func:
        mock_func.return_value = "mocked"
        result = call_function()
        assert result == "mocked"

# Patch object attribute
def test_patch_object():
    with patch.object(MyClass, "method", return_value="mocked"):
        obj = MyClass()
        assert obj.method() == "mocked"

# Patch dictionary
def test_patch_dict():
    original_dict = {"key": "original"}

    with patch.dict(original_dict, {"key": "patched", "new_key": "new"}):
        assert original_dict["key"] == "patched"
        assert original_dict["new_key"] == "new"

    # Original restored
    assert original_dict["key"] == "original"
    assert "new_key" not in original_dict

# pytest-mock plugin (cleaner syntax)
def test_with_mocker(mocker):
    """Using pytest-mock plugin."""
    mock_db = mocker.patch("myapp.database.connect")
    mock_db.return_value.query.return_value = [1, 2, 3]

    result = get_items()

    assert len(result) == 3
    mock_db.assert_called_once()

# Spy (partial mocking)
def test_spy(mocker):
    """Spy on real object, track calls but use real implementation."""
    spy_logger = mocker.spy(logging, "info")

    log_message("test")

    spy_logger.assert_called_once_with("test")

# Mock assertions
def test_mock_assertions():
    mock = Mock()

    mock.method(1, 2, key="value")

    # Various assertions
    mock.method.assert_called()
    mock.method.assert_called_once()
    mock.method.assert_called_with(1, 2, key="value")
    mock.method.assert_called_once_with(1, 2, key="value")

    mock.method(3, 4)
    mock.method.assert_any_call(1, 2, key="value")
    assert mock.method.call_count == 2

    # Check call list
    assert mock.method.call_args_list == [
        call(1, 2, key="value"),
        call(3, 4)
    ]

# Using ANY matcher
def test_any_matcher():
    mock = Mock()
    mock.method("value", 123)

    mock.method.assert_called_with(ANY, 123)  # First arg can be anything
    mock.method.assert_called_with("value", ANY)  # Second arg can be anything
```

## Exception Testing

```python
# Basic exception testing
def test_raises_exception():
    with pytest.raises(ValueError):
        raise ValueError("error message")

# Check exception message
def test_exception_message():
    with pytest.raises(ValueError, match="invalid value"):
        raise ValueError("invalid value provided")

# Check exception message with regex
def test_exception_regex():
    with pytest.raises(ValueError, match=r"value \d+ is invalid"):
        raise ValueError("value 42 is invalid")

# Capture exception for inspection
def test_exception_details():
    with pytest.raises(ValueError) as exc_info:
        raise ValueError("detailed message")

    assert "detailed" in str(exc_info.value)
    assert exc_info.type is ValueError

# Test that exception is NOT raised
def test_no_exception():
    try:
        result = safe_operation()
        assert result is not None
    except Exception:
        pytest.fail("Unexpected exception raised")

# Test specific exception attributes
class CustomError(Exception):
    def __init__(self, code: int, message: str):
        self.code = code
        super().__init__(message)

def test_custom_exception():
    with pytest.raises(CustomError) as exc_info:
        raise CustomError(404, "Not found")

    assert exc_info.value.code == 404
    assert str(exc_info.value) == "Not found"

# pytest.warns for warnings
def test_deprecation_warning():
    with pytest.warns(DeprecationWarning):
        deprecated_function()

# Multiple possible exceptions
def test_multiple_exceptions():
    with pytest.raises((ValueError, TypeError)):
        risky_operation()
```

## Coverage and Reporting

```bash
# Install coverage tools
pip install pytest-cov coverage

# Run with coverage
pytest --cov=myapp

# HTML report
pytest --cov=myapp --cov-report=html
# Open htmlcov/index.html

# Terminal report with missing lines
pytest --cov=myapp --cov-report=term-missing

# XML report (for CI)
pytest --cov=myapp --cov-report=xml

# Fail if coverage below threshold
pytest --cov=myapp --cov-fail-under=80

# Coverage for specific paths
pytest --cov=myapp/core --cov=myapp/utils

# Show test contexts (which tests hit which lines)
pytest --cov=myapp --cov-context=test

# .coveragerc configuration
"""
[run]
source = myapp
omit =
    */tests/*
    */migrations/*
    */__init__.py

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:
"""
```

## Pytest Configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

# Markers
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
    "smoke: marks tests as smoke tests",
]

# Command line options
addopts = [
    "--strict-markers",  # Error on unknown markers
    "--strict-config",   # Error on unknown config
    "--tb=short",        # Shorter traceback format
    "-ra",               # Show summary of all test outcomes
    "--cov=myapp",       # Coverage
    "--cov-report=term-missing",
]

# Ignore paths
norecursedirs = [
    ".*",
    "build",
    "dist",
    "*.egg",
    "venv",
]

# Warning filters
filterwarnings = [
    "error",  # Turn warnings into errors
    "ignore::DeprecationWarning",
    "ignore::PendingDeprecationWarning",
]

# Log settings
log_cli = true
log_cli_level = "INFO"
log_cli_format = "%(asctime)s [%(levelname)s] %(message)s"
log_cli_date_format = "%Y-%m-%d %H:%M:%S"
```

## Pytest Plugins

```python
# Popular pytest plugins

# pytest-asyncio - Test async code
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_operation()
    assert result == "expected"

# pytest-timeout - Prevent hanging tests
@pytest.mark.timeout(5)
def test_with_timeout():
    potentially_hanging_operation()

# pytest-xdist - Parallel test execution
# pytest -n auto  # Use all CPU cores
# pytest -n 4     # Use 4 workers

# pytest-mock - Better mocking
def test_with_mocker(mocker):
    mock = mocker.patch("module.function")
    mock.return_value = "value"

# pytest-freezegun - Mock datetime
from freezegun import freeze_time

@freeze_time("2024-01-01 12:00:00")
def test_with_frozen_time():
    assert datetime.now() == datetime(2024, 1, 1, 12, 0, 0)

# pytest-benchmark - Performance testing
def test_performance(benchmark):
    result = benchmark(function_to_benchmark, arg1, arg2)
    assert result == expected

# pytest-randomly - Randomize test order
# Automatically installed, use --randomly-dont-shuffle to disable

# pytest-sugar - Better test output
# Just install, no code changes needed

# pytest-html - HTML test reports
# pytest --html=report.html

# pytest-datadir - Test data management
def test_with_datadir(datadir):
    # datadir points to tests/test_module/test_function/
    data = (datadir / "input.json").read_text()

# pytest-django - Django testing
@pytest.mark.django_db
def test_user_model():
    user = User.objects.create(username="alice")
    assert user.username == "alice"

# pytest-flask - Flask testing
def test_flask_endpoint(client):
    response = client.get("/api/users")
    assert response.status_code == 200
```

## Advanced Patterns

```python
# Custom fixtures with yield
@pytest.fixture
def transaction():
    """Rollback database after test."""
    trans = database.begin()
    yield trans
    trans.rollback()

# Fixture finalization
@pytest.fixture
def resource(request):
    res = acquire_resource()

    def cleanup():
        res.release()

    request.addfinalizer(cleanup)
    return res

# Parametrize from file
import json

def load_test_cases():
    with open("test_cases.json") as f:
        return json.load(f)

@pytest.mark.parametrize("test_case", load_test_cases())
def test_from_file(test_case):
    assert validate(test_case["input"]) == test_case["expected"]

# Dynamic test generation
def pytest_generate_tests(metafunc):
    """Generate tests dynamically."""
    if "scenario" in metafunc.fixturenames:
        scenarios = load_scenarios()
        metafunc.parametrize("scenario", scenarios)

# Hooks for test setup
def pytest_runtest_setup(item):
    """Run before each test."""
    print(f"Setting up {item.name}")

def pytest_runtest_teardown(item):
    """Run after each test."""
    print(f"Tearing down {item.name}")

# Test result handling
@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Access test results."""
    outcome = yield
    report = outcome.get_result()

    if report.when == "call" and report.failed:
        # Handle test failure
        print(f"Test {item.name} failed")

# Shared fixtures in conftest.py
# tests/conftest.py
import pytest

@pytest.fixture(scope="session")
def app():
    """Application instance shared across all tests."""
    app = create_app("testing")
    return app

@pytest.fixture
def client(app):
    """Test client for making requests."""
    return app.test_client()

# Plugin development
class MyPlugin:
    def pytest_configure(self, config):
        """Called at startup."""
        pass

    def pytest_collection_modifyitems(self, items):
        """Modify collected tests."""
        pass

def pytest_configure(config):
    config.pluginmanager.register(MyPlugin(), "myplugin")
```

## Best Practices

1. **Use fixtures for setup/teardown**: Don't use setUp/tearDown methods
2. **Parametrize extensively**: Test multiple cases with one function
3. **Use markers for test organization**: Skip, xfail, slow, integration
4. **Keep tests isolated**: Each test should run independently
5. **Use tmp_path for file operations**: Don't pollute working directory
6. **Mock external dependencies**: Tests should be fast and reliable
7. **Test edge cases**: Empty lists, None values, boundaries
8. **Use descriptive test names**: test_user_creation_with_invalid_email
9. **One assertion per test (usually)**: Makes failures clear
10. **Use pytest-cov**: Aim for 80%+ coverage
11. **Run tests in random order**: Catches hidden dependencies
12. **Use conftest.py**: Share fixtures across test files
13. **Don't test implementation**: Test behavior, not internals
14. **Use factories for complex objects**: Easier test data creation
15. **Write tests first (TDD)**: Red → Green → Refactor
