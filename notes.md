# PostgreSQL Anonymizer

A free PostgreSQL extension from Dalibo, released under the PostgreSQL licence. It is not an official PostgreSQL project. It masks PII using rules declared on database columns.

## Pros
- Maintained
- Feature rich, with six masking methods that all use the same rules:
  - Anonymous Dumps: export the masked data to an SQL file
  - Static Masking: overwrite the PII in the database according to the rules
  - Dynamic Masking: show masked values only to masked users
  - Replica Masking: create an anonymised clone of a database
  - Masking Views: create dedicated views for masked users
  - Masking Data Wrappers: apply the rules to external data
- PII detection: `anon.detect('en_US')` finds PII columns by column name only. It can return false positives and miss oddly named columns or free text. Only the `en_US` and `fr_FR` dictionaries exist. Other languages (e.g. `en_UK`, `en_GB`) silently return no rows. We could use it in CI and tests.
- Built-in anonymity measure: k-anonymity, e.g. `SELECT anon.k_anonymity('address');`. Label the quasi-identifier columns first.
- Random masking (`fake_*`) keeps relations intact because keys are not masked. Tested: after restoring the dump into an empty database, joins across the masked tables still returned every row.

## Cons
- It requires installing an extension on the database. We therefore need a separate copy of the production database with the extension installed, and we dump the masked data from that copy.
- The data in the database is not changed. A masked role sees fake values, and `pg_dump` run as that role writes them to the file. The source database still holds the raw PII, so the copy must run inside the production boundary.
- We are unlikely to be able to install the extension on RDS (not confirmed).
- Pseudonymisation is the default. Real anonymisation is possible (`fake_*`, `noise()`, `generalize_*`, `shuffle_column`, `k_anonymity()`), but the tool does not certify that the result is anonymous. We would need a check that blocks `pseudo_*`, so that only real anonymisation is generated.
- Random masking gives a different value per row, per table and per run. The same person looks different in each table, and two dumps cannot be compared. Foreign keys still work, so this is acceptable for us.
- Configuration is SQL (`SECURITY LABEL`s) rather than YAML. This may not be a drawback, but it differs from django-db-anonimiser.

---- OTHER (just for me)

## Features
- Rules are SQL `SECURITY LABEL`s on columns, which can be stored in git
- Built-in fake generators (`fake_email()`, `fake_address()`, ...)
- Deterministic masks (`pseudo_*`): the same seed gives the same fake value
- Method used in the spike: Anonymous Dumps, built on Dynamic Masking

## Also learnt
- In version 3.x there is no `pg_dump_anon` command. Use a masked role with plain `pg_dump` (`--exclude-extension` needs pg_dump 17 or later).
- The `MASKED` label has no effect until `anon.transparent_dynamic_masking` is on.
- `anon.init()` is required. Without it, the `pseudo_*` and `fake_*` functions return NULL.
- A column with no rule is dumped unmasked (`anon.privacy_by_default` is off), so new columns are exposed by default.
- To enforce coverage: `anon.privacy_by_default` broke the dump in our setup (permission and `pg_dump` errors; not investigated). Instead, CI can fail if `anon.detect()` returns a column with no `SECURITY LABEL`:
```
SELECT d.table_name::text, d.column_name FROM anon.detect('en_US') d
WHERE NOT EXISTS (SELECT 1 FROM pg_seclabels s WHERE s.provider='anon' AND s.objtype='column'
  AND s.objname = d.table_name::text||'.'||d.column_name);
```
- `anon.salt` is empty by default, so pseudo values are predictable. Set a secret salt and keep it out of git.
- When seeded by row id, `pseudo_*` does not mask the same person the same way across tables (not tested properly).
- Do not mask primary or foreign key columns: joins would break.
- The image is amd64 only and has no pgvector. A custom image with both is possible (`apt install postgresql-18-pgvector` on the Dalibo image; untested).
- Greenmask needs no server extension. This is a point in its favour if RDS cannot run Anonymizer.
- `docker exec psql` needs no password (trust authentication on the Unix socket). Connections from outside the container do.

## Real anonymisation (hard requirement)
Status: the tool can do it, but not by default, and it never proves that the result is anonymous. The spike first used `pseudo_*` (pseudonymisation only), then switched to random `fake_*` rules on a few name and email columns.

### Techniques available
| Technique | Functions | Spike status |
|---|---|---|
| Random substitution (no link to the original) | `fake_email()`, `fake_first_name()`, `fake_last_name()`, `fake_address()`, `fake_city()`, `fake_postcode()`, `random_phone()`, `random_date()`, `random_date_between()`, `random_int_between()`, `random_in(array)`, `random_string()` | Tested: the output differs on every call and every dump |
| Deterministic substitution (pseudonymisation) | `pseudo_email(seed)`, `pseudo_first_name(seed)`, `pseudo_last_name(seed)` | Tested: the same seed gives the same output. A secret `anon.salt` changes the output. Not anonymous |
| Partial scrambling | `partial()`, `partial_email()` | Tested: `da******@ex******.com`. Weak: it leaks the prefix and the length |
| Noise | `noise(value, ratio)`, `dnoise(value, interval)` | Tested: `100` became `100.0129`, and the same date gives a different result on each call |
| Generalisation | `generalize_daterange(date, 'decade')`, `generalize_int4range(int, step)` | Tested: `1987-06-15` became `[1980-01-01,1990-01-01)`, and `37` became `[30,40)` |
| Shuffling | `shuffle_column(table, column, pk)` | Not tried. It changes data in place (static masking), so it is likely not usable with the dump-as-masked-role approach (not confirmed) |
| Local differential privacy | `ldp_grrm()`, `ldp_grrm_pttt()` | Listed only, not tried |
| Free text / images | `lorem_ipsum()`, `image_blur()` | Listed only, not tried |
| Remove / constant | `MASKED WITH VALUE NULL`, `VALUE $$REDACTED$$` | Tested |

### Measuring it: k-anonymity
- Label the quasi-identifiers, then ask for k: `SECURITY LABEL FOR k_anonymity ON COLUMN address.postal_code IS 'QUASI IDENTIFIER';` then `SELECT anon.k_anonymity('address');` (the table and column names are examples)
- Tried on an address table with postal code and district as quasi-identifiers: **k = 1**. At least one row is unique on those two columns alone.
- k only covers the columns you label. k-anonymity alone does not protect against attribute disclosure.

### What is not anonymous in our current output
- Only a few name and email columns are masked (with random `fake_*`).
- The dump still contains primary and foreign keys, uuids, dates, locations (city, district), amounts and timestamps. In combination, these can single a person out.
- Every column without a rule, including new ones, is dumped as real data.

### The relations trade-off
- Random masking (`fake_*`) keeps foreign keys valid (tested, see Pros). It gives a different value per row, per table and per run.
- Keeping keys (e.g. ids, uuids) keeps joins working, but the keys remain linkable identifiers. A dump with intact keys is therefore arguably not anonymous.
- Masking the keys themselves needs the same deterministic mapping on both sides of every foreign key. Not tried.
- For each column, decide whether it needs consistency (use `pseudo_*` with a secret salt) or must be random.
- Random values could collide on a `UNIQUE` column (e.g. a username) and break the restore. Not tested.

### What a real-anonymisation setup would need
1. Classify every column as direct identifier, quasi-identifier, sensitive or safe. `anon.detect()` is only a starting point, because it checks column names only.
2. Direct identifiers: use random `fake_*` (no seed) or NULL.
3. Quasi-identifiers: generalise them or add noise, then check `k_anonymity()` against an agreed target k.
4. Keys: decide per key whether to keep it or remap it consistently on both sides.
5. Free text, JSON and images: there is no built-in detection. Replace the whole column. Not tried on JSON.
6. Any remaining `pseudo_*` needs a secret `anon.salt` (not stored in git).
7. CI: fail on a detected column with no label (query above), on k below the target, and on any rule that uses `pseudo_`. The extension does not ban `pseudo_*`, so this check lists the offending rules. Tested: 0 rows with `fake_*` rules, 3 rows with `pseudo_*` rules:
```
SELECT objname, label FROM pg_seclabels
WHERE provider='anon' AND objtype='column' AND label ILIKE '%pseudo\_%';
```
8. Get privacy or legal sign-off on what counts as anonymous. The tool does not check linkage to outside datasets.
