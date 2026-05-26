-- Archived DDL for pjc_costs (removed from active DDL)
CREATE TABLE pjc_costs (
  interface_id            VARCHAR2(100) PRIMARY KEY,
  business_unit           VARCHAR2(200),
  organization_name       VARCHAR2(200),
  unit_of_measure_name    VARCHAR2(100),
  supplier_name           VARCHAR2(200),
  project_number          VARCHAR2(50),
  task_number             VARCHAR2(50),
  expenditure_item_date   DATE,
  denom_raw_cost          NUMBER,
  quantity                NUMBER,
  doc_entry_name          VARCHAR2(200),
  document_name           VARCHAR2(200),
  orig_transaction_reference VARCHAR2(200),
  contract_number         VARCHAR2(100),
  funding_source_name     VARCHAR2(200),
  denom_currency_code     VARCHAR2(50),
  expenditure_comment     VARCHAR2(4000),
  attribute1              VARCHAR2(4000),
  person_name             VARCHAR2(200),
  person_number           VARCHAR2(50)
);
