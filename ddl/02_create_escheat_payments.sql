-- Create escheat_payments table
CREATE TABLE escheat_payments (
  check_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  check_date     DATE,
  supplier_name  VARCHAR2(200),
  supplier_number VARCHAR2(50),
  invoice_id     NUMBER,
  batch_id       NUMBER,
  void_date      DATE
);
