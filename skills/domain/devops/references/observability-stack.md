# Observability Stack Complete Reference

Complete monitoring and logging setup with Prometheus, Grafana, Loki, Jaeger, and OpenTelemetry.

## Prometheus Configuration

### prometheus.yml
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-east-1'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

# Load rules
rule_files:
  - /etc/prometheus/rules/*.yml

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Kubernetes API server
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  # Kubernetes nodes
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  # Kubernetes pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

  # Application services
  - job_name: 'myapp'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - production
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_label_app]
        action: keep
        regex: myapp
      - source_labels: [__meta_kubernetes_endpoint_port_name]
        action: keep
        regex: metrics
```

### Alert Rules
```yaml
# /etc/prometheus/rules/alerts.yml
groups:
  - name: application_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
            /
            sum(rate(http_requests_total[5m])) by (service)
          ) > 0.05
        for: 5m
        labels:
          severity: critical
          component: backend
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"
          runbook: "https://wiki.example.com/runbooks/high-error-rate"

      # High latency (P95)
      - alert: HighLatencyP95
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
          ) > 1
        for: 10m
        labels:
          severity: warning
          component: backend
        annotations:
          summary: "High P95 latency on {{ $labels.service }}"
          description: "P95 latency is {{ $value | humanizeDuration }}"

      # Pod crash looping
      - alert: PodCrashLooping
        expr: |
          rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
          description: "Pod has restarted {{ $value }} times in the last 15 minutes"

      # High memory usage
      - alert: HighMemoryUsage
        expr: |
          (
            container_memory_working_set_bytes
            /
            container_spec_memory_limit_bytes
          ) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage in {{ $labels.namespace }}/{{ $labels.pod }}"
          description: "Memory usage is {{ $value | humanizePercentage }} of limit"

      # Disk space low
      - alert: DiskSpaceLow
        expr: |
          (
            node_filesystem_avail_bytes{mountpoint="/"}
            /
            node_filesystem_size_bytes{mountpoint="/"}
          ) < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Only {{ $value | humanizePercentage }} disk space available"

  - name: infrastructure_alerts
    interval: 1m
    rules:
      # Node down
      - alert: NodeDown
        expr: up{job="kubernetes-nodes"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.instance }} is down"

      # Too many pods
      - alert: TooManyPods
        expr: |
          sum(kube_pod_info) by (node) > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Node {{ $labels.node }} has too many pods"
          description: "Running {{ $value }} pods on node"
```

### Recording Rules (Pre-aggregation)
```yaml
# /etc/prometheus/rules/recording.yml
groups:
  - name: http_metrics
    interval: 30s
    rules:
      # Request rate by service
      - record: service:http_requests:rate5m
        expr: |
          sum(rate(http_requests_total[5m])) by (service, method, status)

      # Error rate by service
      - record: service:http_errors:rate5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)

      # P95 latency by service
      - record: service:http_latency:p95
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
          )

      # P99 latency by service
      - record: service:http_latency:p99
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
          )
```

## Application Instrumentation

### Python with prometheus_client
```python
from prometheus_client import Counter, Histogram, Gauge, Info, start_http_server
from prometheus_client import generate_latest, REGISTRY
import time
import functools

# Define metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0, 2.5, 5.0, 10.0)
)

active_connections = Gauge(
    'active_connections',
    'Number of active connections'
)

database_connections = Gauge(
    'database_connections',
    'Database connection pool status',
    ['state']  # active, idle
)

app_info = Info(
    'app',
    'Application information'
)

# Set static info
app_info.info({
    'version': '1.0.0',
    'environment': 'production',
    'service': 'api'
})

# Decorator for automatic instrumentation
def track_request(endpoint):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            method = 'GET'  # Extract from request

            # Track active connections
            active_connections.inc()

            # Time the request
            start = time.time()
            try:
                result = func(*args, **kwargs)
                status = 200  # Extract from response
                return result
            except Exception as e:
                status = 500
                raise
            finally:
                duration = time.time() - start

                # Record metrics
                http_requests_total.labels(
                    method=method,
                    endpoint=endpoint,
                    status=status
                ).inc()

                http_request_duration_seconds.labels(
                    method=method,
                    endpoint=endpoint
                ).observe(duration)

                active_connections.dec()

        return wrapper
    return decorator

# Flask integration
from flask import Flask, request
from werkzeug.middleware.dispatcher import DispatcherMiddleware

app = Flask(__name__)

@app.route('/api/users')
@track_request('/api/users')
def get_users():
    return {'users': []}

@app.route('/health')
def health():
    return {'status': 'healthy'}

@app.route('/metrics')
def metrics():
    return generate_latest(REGISTRY)

# Or use middleware for automatic tracking
from prometheus_flask_exporter import PrometheusMetrics
metrics = PrometheusMetrics(app)

# Start metrics server on separate port
if __name__ == '__main__':
    start_http_server(9090)  # Metrics on :9090
    app.run(port=8080)       # App on :8080
```

### Node.js with prom-client
```javascript
const client = require('prom-client');
const express = require('express');

// Create a Registry
const register = new client.Registry();

// Add default metrics
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'endpoint', 'status'],
  registers: [register]
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'endpoint'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1.0, 2.5, 5.0, 10.0],
  registers: [register]
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register]
});

// Express middleware
function metricsMiddleware(req, res, next) {
  const start = Date.now();

  activeConnections.inc();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;

    httpRequestsTotal.labels(
      req.method,
      req.route?.path || req.path,
      res.statusCode
    ).inc();

    httpRequestDuration.labels(
      req.method,
      req.route?.path || req.path
    ).observe(duration);

    activeConnections.dec();
  });

  next();
}

const app = express();

app.use(metricsMiddleware);

app.get('/api/users', (req, res) => {
  res.json({ users: [] });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(8080);
```

## Grafana Dashboards

### Dashboard JSON (Application Overview)
```json
{
  "dashboard": {
    "title": "Application Overview",
    "panels": [
      {
        "id": 1,
        "type": "graph",
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{ service }}"
          }
        ],
        "yaxes": [
          {
            "format": "reqps",
            "label": "Requests/sec"
          }
        ]
      },
      {
        "id": 2,
        "type": "graph",
        "title": "Error Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{ service }}"
          }
        ],
        "yaxes": [
          {
            "format": "percentunit",
            "label": "Error Rate"
          }
        ],
        "alert": {
          "conditions": [
            {
              "evaluator": {
                "type": "gt",
                "params": [0.05]
              },
              "query": {
                "params": ["A", "5m", "now"]
              }
            }
          ]
        }
      },
      {
        "id": 3,
        "type": "graph",
        "title": "Latency Percentiles",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "{{ service }} p50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "{{ service }} p95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
            "legendFormat": "{{ service }} p99"
          }
        ],
        "yaxes": [
          {
            "format": "s",
            "label": "Duration"
          }
        ]
      },
      {
        "id": 4,
        "type": "stat",
        "title": "Uptime",
        "targets": [
          {
            "expr": "avg(up{job=\"myapp\"})",
            "instant": true
          }
        ],
        "options": {
          "reduceOptions": {
            "calcs": ["lastNotNull"]
          },
          "thresholds": {
            "steps": [
              {"value": 0, "color": "red"},
              {"value": 0.99, "color": "yellow"},
              {"value": 1, "color": "green"}
            ]
          }
        }
      }
    ],
    "refresh": "30s",
    "time": {
      "from": "now-6h",
      "to": "now"
    }
  }
}
```

### Kubernetes Dashboard
```json
{
  "dashboard": {
    "title": "Kubernetes Cluster",
    "panels": [
      {
        "title": "Pod CPU Usage",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"production\"}[5m])) by (pod)",
            "legendFormat": "{{ pod }}"
          }
        ]
      },
      {
        "title": "Pod Memory Usage",
        "targets": [
          {
            "expr": "sum(container_memory_working_set_bytes{namespace=\"production\"}) by (pod) / 1024 / 1024 / 1024",
            "legendFormat": "{{ pod }}"
          }
        ]
      },
      {
        "title": "Network I/O",
        "targets": [
          {
            "expr": "sum(rate(container_network_receive_bytes_total[5m])) by (pod)",
            "legendFormat": "{{ pod }} rx"
          },
          {
            "expr": "sum(rate(container_network_transmit_bytes_total[5m])) by (pod)",
            "legendFormat": "{{ pod }} tx"
          }
        ]
      }
    ]
  }
}
```

## Loki for Logging

### Loki Configuration
```yaml
# loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2023-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 720h  # 30 days
```

### Promtail Configuration (Log Shipper)
```yaml
# promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Kubernetes pod logs
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    pipeline_stages:
      - docker: {}
      - json:
          expressions:
            level: level
            message: message
            timestamp: timestamp
      - labels:
          level:
          service:
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_pod_label_version]
        target_label: version
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod

  # Application logs
  - job_name: application
    static_configs:
      - targets:
          - localhost
        labels:
          job: myapp
          __path__: /var/log/myapp/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            logger: logger
            message: message
            request_id: request_id
      - timestamp:
          source: timestamp
          format: RFC3339
      - labels:
          level:
          logger:
      - output:
          source: message
```

### LogQL Queries
```
# Show all logs from myapp
{app="myapp"}

# Filter by log level
{app="myapp"} |= "level=error"

# JSON parsing
{app="myapp"} | json | level="error"

# Regex filtering
{app="myapp"} |~ "user_id=[0-9]+"

# Rate of errors
rate({app="myapp"} |= "error" [5m])

# Top 10 error messages
topk(10, sum by (message) (rate({app="myapp"} |= "error" [5m])))

# Logs for specific request
{app="myapp"} | json | request_id="abc123"

# Slow requests (> 1s)
{app="myapp"} | json | duration > 1.0
```

## Jaeger for Distributed Tracing

### Jaeger Deployment (Kubernetes)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        env:
        - name: COLLECTOR_ZIPKIN_HOST_PORT
          value: ":9411"
        - name: SPAN_STORAGE_TYPE
          value: elasticsearch
        - name: ES_SERVER_URLS
          value: http://elasticsearch:9200
        ports:
        - containerPort: 5775
          protocol: UDP
        - containerPort: 6831
          protocol: UDP
        - containerPort: 6832
          protocol: UDP
        - containerPort: 5778
          protocol: TCP
        - containerPort: 16686  # UI
          protocol: TCP
        - containerPort: 14268  # Collector
          protocol: TCP
        - containerPort: 14250  # gRPC
          protocol: TCP
        - containerPort: 9411   # Zipkin
          protocol: TCP
```

### OpenTelemetry Collector
```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

  memory_limiter:
    check_interval: 1s
    limit_mib: 512

  attributes:
    actions:
      - key: environment
        value: production
        action: insert

exporters:
  # Send to Jaeger
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true

  # Send to Prometheus
  prometheus:
    endpoint: "0.0.0.0:8889"

  # Send logs to Loki
  loki:
    endpoint: http://loki:3100/loki/api/v1/push

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [jaeger]

    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]

    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [loki]
```

### Python OpenTelemetry Setup
```python
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

# Configure tracer
trace.set_tracer_provider(TracerProvider())
otlp_exporter = OTLPSpanExporter(endpoint="otel-collector:4317", insecure=True)
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))

# Configure metrics
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint="otel-collector:4317", insecure=True)
)
metrics.set_meter_provider(MeterProvider(metric_readers=[metric_reader]))

# Auto-instrument Flask
from flask import Flask
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

# Auto-instrument requests library
RequestsInstrumentor().instrument()

# Auto-instrument SQLAlchemy
from sqlalchemy import create_engine
engine = create_engine("postgresql://...")
SQLAlchemyInstrumentor().instrument(engine=engine)

# Manual tracing
tracer = trace.get_tracer(__name__)

@app.route('/api/process')
def process_data():
    with tracer.start_as_current_span("process_data") as span:
        span.set_attribute("user_id", "123")
        span.set_attribute("action", "process")

        # Add event
        span.add_event("Processing started")

        # Nested spans
        with tracer.start_as_current_span("fetch_from_db"):
            data = fetch_data()

        with tracer.start_as_current_span("transform"):
            result = transform(data)

        span.add_event("Processing completed")

        return result
```

## Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/xxx'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'

  routes:
    # Critical alerts to PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty'
      continue: true

    # All alerts to Slack
    - match_re:
        severity: (warning|critical)
      receiver: 'slack'

receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://webhook-receiver/alert'

  - name: 'slack'
    slack_configs:
      - channel: '#alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'xxx'
        description: '{{ .GroupLabels.alertname }}'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
```

## Best Practices

1. **Metrics**
   - Use RED method (Rate, Errors, Duration)
   - Add USE method for resources (Utilization, Saturation, Errors)
   - Label cardinality matters (avoid high-cardinality labels)
   - Use histograms for latency

2. **Logging**
   - Structured logging (JSON)
   - Include correlation IDs
   - Don't log sensitive data
   - Use appropriate log levels
   - Centralize logs

3. **Tracing**
   - Sample strategically (not 100%)
   - Add context to spans
   - Use semantic conventions
   - Trace critical paths

4. **Alerting**
   - Alert on symptoms, not causes
   - Make alerts actionable
   - Include runbook links
   - Avoid alert fatigue
   - Test alert rules
