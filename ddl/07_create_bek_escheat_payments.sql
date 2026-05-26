-- Create bek_escheat_payments table
CREATE TABLE bek_escheat_payments (
  id                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  check_id          NUMBER,
  supplier_name     VARCHAR2(200),
  supplier_number   VARCHAR2(50),
  invoice_id        NUMBER,
  check_date        DATE
);
