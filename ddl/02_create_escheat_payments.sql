-- Create escheat_payments table
CREATE TABLE escheat_payments (
  id                 NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  check_id           NUMBER,
  check_date         DATE,
  check_number       VARCHAR2(100),
  supplier_name      VARCHAR2(200),
  supplier_number    VARCHAR2(50),
  supplier_site_name VARCHAR2(200),
  invoice_id         NUMBER,
  invoice_date       VARCHAR2(20),
  invoice_number     VARCHAR2(100),
  payment_amount     NUMBER,
  bu_name            VARCHAR2(200),
  payment_status     VARCHAR2(50),
  batch_id           NUMBER,
  void_date          DATE
);
