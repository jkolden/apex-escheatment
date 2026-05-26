-- Create com_remittance_fees table
CREATE TABLE com_remittance_fees (
  id                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  invoice_id        NUMBER,
  installment_number NUMBER,
  amount            NUMBER,
  creation_date     DATE
);
