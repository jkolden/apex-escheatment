-- Run all table creation scripts in order
@01_create_com_invoices.sql
@02_create_escheat_payments.sql
@03_create_com_api_log.sql
@04_create_com_remittance_fees.sql
@05_create_otbi_billing_events.sql
@06_create_republic_invoices.sql
@07_create_bek_escheat_payments.sql
