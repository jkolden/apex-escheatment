# Escheatment APEX Application

Oracle APEX application for processing escheatment (unclaimed property) payments against Oracle Fusion Cloud. When payments to suppliers go unclaimed past a statutory holding period, states require the funds be turned over. This app automates that process.

## How It Works

The app has two pages, each driving a distinct workflow:

**Escheatments** — Processes unclaimed disbursements. For a selected payment the app:
1. Voids the original payment via the Payables Payments REST API
2. Looks up the supplier and site via the Suppliers REST API
3. Creates a third-party payment relationship redirecting funds to the state (e.g. City of Boston)
4. Updates the invoice installment remit-to address

**Third Party Payments** — Processes unpaid invoice installments. For a selected installment the app:
1. Reduces the invoice header amount by the intercept fee ($15)
2. Adds a new invoice line for the fee (distribution: `1150-2022-92340-44760-1000-0000-00000000`)
3. Creates a third-party payment relationship redirecting the remaining balance to the state
4. Updates the installment with the new amount and remit-to address

Both workflows pull data from Fusion Cloud via OTBI SOAP queries and write back via Fusion REST APIs. All API calls are logged to `com_api_log` with batch IDs for traceability.

## Configuration

Set these package variables per environment before calling any procedures:

| Variable | Purpose | Example |
|----------|---------|---------|
| `g_instance` | Fusion Cloud instance name | `fa-eseg` |
| `g_domain` | Fusion Cloud domain suffix | `-saasfademo1.ds-fa.oraclepdemos.com` |
| `g_user` | OTBI session user | `gia.roberts` |
| `g_password` | Fusion Cloud password | *(set at runtime)* |
| `g_payables_user` | User for Payables REST calls | `gia.roberts` |
| `g_purchasing_user` | User for Suppliers REST calls | `eleanor.white` |

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
