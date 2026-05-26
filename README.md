# Escheatment APEX Application

Oracle APEX application for processing escheatment payments against Oracle Fusion Cloud.

## Files

- `f268709.sql` — APEX 26.1 application export (App 268709).
- `escheat_pkg.sql` — PL/SQL package specification.
- `escheat_pkg.plb` — PL/SQL package body.
- `ddl/00_create_all_tables.sql` — runs all table creation scripts in order.
- `ddl/01_create_com_invoices.sql` — creates `com_invoices`.
- `ddl/02_create_escheat_payments.sql` — creates `escheat_payments`.
- `ddl/02_create_sequences.sql` — creates sequences (`api_seq`, `api_batch_seq`, `generic_seq`).
- `ddl/03_create_com_api_log.sql` — creates `com_api_log`.
- `ddl/04_create_com_remittance_fees.sql` — creates `com_remittance_fees`.

## Quick Start

Run as the schema owner (e.g. `MYFUSION`):

```sql
@ddl/00_create_all_tables.sql
@ddl/02_create_sequences.sql
@escheat_pkg.sql
@escheat_pkg.plb
```

Then import `f268709.sql` via APEX Application Builder.

## Notes

- Tables use `GENERATED ALWAYS AS IDENTITY` for primary keys.
- The package requires `EXECUTE` privileges on `APEX_WEB_SERVICE`, `APEX_JSON`, and appropriate network ACLs for HTTPS calls to Oracle Fusion Cloud REST and OTBI SOAP endpoints.
- Set `escheat_pkg.g_password` at runtime before calling any procedures.
