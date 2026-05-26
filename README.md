# Escheatment package — DDL and repo notes

This folder contains DDL scripts and notes to initialize the database objects used by the escheatment packages.

Files:

- `ddl/00_create_all_tables.sql` — runs all table creation scripts in order.
- `ddl/01_create_com_invoices.sql` — creates `com_invoices`.
- `ddl/02_create_escheat_payments.sql` — creates `escheat_payments`.
- `ddl/03_create_com_api_log.sql` — creates `com_api_log`.
- `ddl/04_create_com_remittance_fees.sql` — creates `com_remittance_fees`.
- `ddl/05_create_otbi_billing_events.sql` — creates `otbi_billing_events`.
- `ddl/06_create_republic_invoices.sql` — creates `republic_invoices`.
- `ddl/07_create_bek_escheat_payments.sql` — creates `bek_escheat_payments`.
- `ddl/02_create_sequences.sql` — creates compatibility sequences (`api_seq`, `api_batch_seq`, `generic_seq`, `otbi_seq`) used by existing code that calls `.NEXTVAL`.

Quick start (run as a DBA or schema owner):

1. Review and adjust column sizes and types in the per-table scripts under `ddl/` to match your production requirements.
2. Run the DDL scripts in order:

```sql
@ddl/00_create_all_tables.sql
@ddl/02_create_sequences.sql
@archive/pjc_errlog.sql
```

3. If you plan to use Git:

```bash
git init
git add .
git commit -m "Initial Escheatment DDL and scripts"
```

Notes:
- Tables use `GENERATED ALWAYS AS IDENTITY` so inserts will auto-populate primary keys. Sequences are retained for compatibility with code that explicitly calls `NEXTVAL`.
- Ensure the schema that runs this code has `EXECUTE` privileges on `APEX_*` packages and appropriate network ACLs for external HTTP(S) calls.
