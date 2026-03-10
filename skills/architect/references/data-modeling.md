# Data Modeling Reference

## Schema Design Principles

| Principle | Guideline |
|-----------|-----------|
| Primary keys | UUID for distributed systems, serial for single-instance |
| Foreign keys | Always enforce (ON DELETE CASCADE or RESTRICT) |
| Normalization | 3NF default; denormalize only with measured query evidence |
| Soft delete | Use `deleted_at` column; hard delete only for GDPR/legal |
| Audit columns | `created_at`, `updated_at` on every table |
| Constraints | CHECK constraints for business rules in the schema |
| Indexes | Create for query patterns, not speculatively |

## Example Schema (PostgreSQL)

```sql
-- Design notes:
--   UUID for distributed compatibility
--   JSONB for flexible attributes (avoids EAV anti-pattern)
--   Partial indexes for query optimization
--   Audit columns on all tables

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT no_self_parent CHECK (id != parent_id)
);

CREATE INDEX idx_categories_parent ON categories(parent_id)
    WHERE parent_id IS NOT NULL;

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price_cents INTEGER NOT NULL,
    category_id UUID NOT NULL REFERENCES categories(id),
    stock INTEGER NOT NULL DEFAULT 0,
    attributes JSONB DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT price_positive CHECK (price_cents >= 0),
    CONSTRAINT stock_non_negative CHECK (stock >= 0)
);

-- Indexes for common queries
CREATE INDEX idx_products_category ON products(category_id)
    WHERE is_active = true;
CREATE INDEX idx_products_created ON products(created_at DESC);
CREATE INDEX idx_products_price ON products(price_cents)
    WHERE is_active = true;

-- Full-text search
CREATE INDEX idx_products_search ON products
    USING GIN (to_tsvector('english', name || ' ' || COALESCE(description, '')));
```

## Audit Trigger Pattern

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to each table:
CREATE TRIGGER update_{table}_updated_at
    BEFORE UPDATE ON {table}
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Index Strategy Decision Table

| Query Pattern | Index Type | Example |
|---------------|-----------|---------|
| Equality lookup | B-tree (default) | `WHERE user_id = ?` |
| Range query | B-tree | `WHERE created_at > ?` |
| Full-text search | GIN | `WHERE to_tsvector(...) @@ to_tsquery(...)` |
| JSONB containment | GIN | `WHERE attributes @> '{"color":"red"}'` |
| Array contains | GIN | `WHERE tags @> ARRAY['sale']` |
| Geospatial | GiST/SP-GiST | `WHERE location <@ circle(...)` |
| Partial (filtered) | Any + WHERE | `WHERE is_active = true` (skip inactive rows) |
| Covering | INCLUDE | Avoid table lookup for common queries |

## Migration Best Practices

| Rule | Why |
|------|-----|
| Always wrap in transaction | Rollback safety |
| Create indexes CONCURRENTLY in production | Avoids table locks |
| ANALYZE tables after bulk inserts | Updates query planner statistics |
| Make migrations reversible | Every UP needs a DOWN |
| Never rename columns directly | Add new, migrate data, drop old |
| Add nullable columns first | Avoids full table rewrite |
| Backfill data in batches | Avoids long-running transactions |

## Normalization vs Denormalization

| Factor | Normalize (3NF) | Denormalize |
|--------|-----------------|-------------|
| Data integrity | Preferred | Risk of inconsistency |
| Write performance | Preferred | Slower (update multiple places) |
| Read performance | Slower (joins) | Preferred |
| Storage | Less duplication | More duplication |
| Query complexity | More joins | Simpler queries |

**Rule**: Start normalized. Denormalize only when you have query performance data showing joins are the bottleneck. Always document why.

## Partitioning Strategies

| Strategy | When | Example |
|----------|------|---------|
| By date/time | Time-series data, logs, events | Monthly partitions |
| By tenant | Multi-tenant SaaS | One partition per tenant |
| By geography | Data residency, GDPR | Region-based partitions |
| By hash | Even distribution needed | Hash of primary key |

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Alternative |
|--------------|---------|-------------|
| EAV (Entity-Attribute-Value) | Unqueryable, no constraints | JSONB column |
| God table | Too many columns, mixed concerns | Split by domain |
| Polymorphic associations | No FK enforcement | Separate join tables |
| Over-indexing | Write overhead, storage waste | Index for measured query patterns |
| Storing money as float | Rounding errors | Integer cents or DECIMAL |
| No constraints | Data corruption | CHECK, NOT NULL, FK |
