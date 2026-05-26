-- Create com_invoices table
CREATE TABLE com_invoices (
  id                  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  invoice_id          NUMBER,
  invoice_date        DATE,
  terms_date          DATE,
  installment_number  NUMBER,
  supplier_name       VARCHAR2(200),
  taxpayer_id         VARCHAR2(50),
  invoice_number      VARCHAR2(100),
  gross_amount        NUMBER,
  adjusted_amount     NUMBER,
  amount_due_remaining NUMBER,
  payment_status      VARCHAR2(20),
  address_name        VARCHAR2(200),
  supplier_number     VARCHAR2(50),
  batch_id            NUMBER
);
