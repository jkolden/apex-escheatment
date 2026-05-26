-- Create com_api_log table
CREATE TABLE com_api_log (
  batch_id        NUMBER,
  seq_id          NUMBER GENERATED ALWAYS AS IDENTITY,
  action          VARCHAR2(50),
  api_fire_date   DATE,
  api             VARCHAR2(200),
  status_code     NUMBER,
  response_payload CLOB
);
