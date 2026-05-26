-- Archived ERR log creation for pjc_costs
BEGIN
  BEGIN
    DBMS_ERRLOG.CREATE_ERROR_LOG(d_table_name => 'PJC_COSTS', d_err_table_name => 'ERR$_PJC_COSTS');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF; -- ignore if already exists
  END;
END;
/
