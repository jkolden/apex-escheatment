-- Create otbi_billing_events table
CREATE TABLE otbi_billing_events (
  id                    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  contract_number       VARCHAR2(100),
  contract_line_number  VARCHAR2(50),
  event_number          VARCHAR2(50),
  event_type            VARCHAR2(100),
  business_unit_name    VARCHAR2(200),
  event_amount          NUMBER,
  contract_type         VARCHAR2(100)
);
