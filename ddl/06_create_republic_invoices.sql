-- Create republic_invoices table
CREATE TABLE republic_invoices (
  transaction_id         VARCHAR2(100) PRIMARY KEY,
  bill_to_postal_code    VARCHAR2(20),
  transaction_number     VARCHAR2(100),
  bill_to_customer       VARCHAR2(200),
  original_amount        NUMBER,
  adjusted_amount        NUMBER,
  amount_due_remaining   NUMBER,
  transaction_date       DATE
);
