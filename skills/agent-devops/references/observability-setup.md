# Observability Setup

## Pillar 1: Structured Logging

```python
import structlog
import logging

# Configure structured logger
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger()

# Usage example
def process_payment(user_id: str, amount: float, currency: str):
    logger.info(
        "payment_processing_started",
        user_id=user_id,
        amount=amount,
        currency=currency,
        request_id=get_request_id(),
        trace_id=get_trace_id(),
    )

    try:
        result = payment_gateway.charge(amount, currency)

        logger.info(
            "payment_successful",
            user_id=user_id,
            transaction_id=result.id,
            amount=amount,
            currency=currency,
            duration_ms=result.duration,
        )

        return result

    except PaymentError as e:
        logger.error(
            "payment_failed",
            user_id=user_id,
            amount=amount,
            currency=currency,
            error_code=e.code,
            error_message=str(e),
            exc_info=True,
        )
        raise
```

## Pillar 2: Prometheus Metrics

```python
from prometheus_client import Counter, Histogram, Gauge

# Counters: Things that only increase
requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

errors_total = Counter(
    'errors_total',
    'Total errors',
    ['error_type', 'severity']
)

# Histograms: Distributions (latency, request size)
request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

# Gauges: Values that go up and down
active_connections = Gauge(
    'active_connections',
    'Number of active connections'
)

queue_size = Gauge(
    'queue_size',
    'Number of items in queue',
    ['queue_name']
)

# Usage in code
@request_duration.labels(method='POST', endpoint='/api/payment').time()
def handle_payment(request):
    requests_total.labels(method='POST', endpoint='/api/payment', status='processing').inc()

    try:
        result = process_payment(request.data)
        requests_total.labels(method='POST', endpoint='/api/payment', status='success').inc()
        return result
    except Exception as e:
        requests_total.labels(method='POST', endpoint='/api/payment', status='error').inc()
        errors_total.labels(error_type=type(e).__name__, severity='high').inc()
        raise
```

## Pillar 3: Distributed Tracing (OpenTelemetry)

```python
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

# Setup tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Export to observability backend
otlp_exporter = OTLPSpanExporter(endpoint="http://tempo:4317")
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Instrument frameworks automatically
FastAPIInstrumentor.instrument()

# Manual instrumentation for business logic
def process_order(order_id: str):
    with tracer.start_as_current_span("process_order") as span:
        span.set_attribute("order.id", order_id)

        with tracer.start_as_current_span("validate_order"):
            validation_result = validate(order_id)
            span.set_attribute("order.valid", validation_result)

        payment_result = payment_service.charge(order_id)
        span.set_attribute("payment.status", payment_result.status)

        if not payment_result.success:
            span.set_status(trace.Status(trace.StatusCode.ERROR))
            span.record_exception(payment_result.error)

        return payment_result
```

## Kubernetes Observability Config

```yaml
# k8s/prometheus-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 15s
    path: /metrics

---
# k8s/grafana-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-dashboard
  labels:
    grafana_dashboard: "1"
data:
  myapp-dashboard.json: |
    {
      "dashboard": {
        "title": "MyApp Metrics",
        "panels": [
          {
            "title": "Request Rate",
            "targets": [{"expr": "rate(http_requests_total[5m])"}]
          },
          {
            "title": "Error Rate",
            "targets": [{"expr": "rate(errors_total[5m])"}]
          },
          {
            "title": "P95 Latency",
            "targets": [{"expr": "histogram_quantile(0.95, http_request_duration_seconds)"}]
          }
        ]
      }
    }
```
