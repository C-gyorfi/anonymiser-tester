## General usage
1. Start a Postgres container with the extension:
```
docker run -d --name anon --platform linux/amd64 \
  -e POSTGRES_DB=app -e POSTGRES_USER=testuser -e POSTGRES_PASSWORD=testpass \
  -p 5433:5432 registry.gitlab.com/dalibo/postgresql_anonymizer:latest
```

2. Load the test schema and data (a plain-SQL dump of the source database):
```
docker exec -i anon psql -v ON_ERROR_STOP=1 -q -U testuser -d app < source_dump.sql
```

3. Create `setup.sql` with the fixed setup (extension, masked role, and the setting that turns masking on):
```SQL
-- setup.sql: fixed setup for PostgreSQL Anonymizer. Users edit rules.sql, not this file.

CREATE EXTENSION IF NOT EXISTS anon;
SELECT anon.init();   -- loads the data used by the pseudo_*/fake_* functions

-- The dumping role: it sees masked data only.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon_dumper') THEN
    CREATE ROLE anon_dumper LOGIN;
  END IF;
END $$;

SECURITY LABEL FOR anon ON ROLE anon_dumper IS 'MASKED';
-- Without this setting, the MASKED label has no effect and the role reads real data.
ALTER ROLE anon_dumper SET anon.transparent_dynamic_masking TO true;
GRANT pg_read_all_data TO anon_dumper;

-- Remove existing masks so that rules.sql is the single source of truth.
SELECT anon.remove_masks_for_all_columns();
```

4. Create `rules.sql`, the only file users edit (`customer` and its columns are examples; use your own tables):
```SQL
-- rules.sql: masking rules.
-- One block per column: the table.column to mask, and how.
--
-- * Do not mask primary or foreign key columns: joins in the dump would break.
-- * A column with no rule goes into the dump unmasked.
-- * Use random masks (fake_*), not pseudo_*. They give a different fake value
--   for every row and every run, so nothing can be traced back to the real value.
--
-- Common masks:
--   anon.fake_first_name()   anon.fake_last_name()   anon.fake_email()
--   anon.fake_address()      anon.fake_postcode()    anon.random_phone()
--   VALUE NULL               VALUE $$REDACTED$$

-- customer
SECURITY LABEL FOR anon ON COLUMN customer.first_name
  IS 'MASKED WITH FUNCTION anon.fake_first_name()';
SECURITY LABEL FOR anon ON COLUMN customer.last_name
  IS 'MASKED WITH FUNCTION anon.fake_last_name()';
SECURITY LABEL FOR anon ON COLUMN customer.email
  IS 'MASKED WITH FUNCTION anon.fake_email()';
```

5. Apply both files:
```
for f in setup.sql rules.sql; do
  docker exec -i anon psql -v ON_ERROR_STOP=1 -q -U testuser -d app < "$f" > /dev/null
done
```

6. Dump as the masked role:
```
docker exec anon pg_dump -U anon_dumper -d app \
  --no-owner --no-privileges --no-security-labels --exclude-extension=anon > anonymised.sql
```

7. Check. The same query returns real data as `testuser` and fake data as `anon_dumper`:
```
docker exec anon psql -U testuser    -d app -c "SELECT first_name, email FROM customer ORDER BY customer_id LIMIT 2"
docker exec anon psql -U anon_dumper -d app -c "SELECT first_name, email FROM customer ORDER BY customer_id LIMIT 2"
grep -c '<a real email from the source data>' anonymised.sql   # expect 0
```