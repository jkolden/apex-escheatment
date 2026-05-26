create or replace package escheat_pkg as

    -- configurable connection settings
    g_instance       varchar2(120) := 'fa-eseg';
    g_domain         varchar2(200) := '-saasfademo1.ds-fa.oraclepdemos.com';
    g_user           varchar2(100) := 'gia.roberts';
    g_password       varchar2(100);
    g_payables_user  varchar2(100) := 'gia.roberts';
    g_purchasing_user varchar2(100) := 'eleanor.white';
    g_batch_id       number;

    -- data extraction (only procedures used by the APEX app)
    procedure get_invoice_installments;
    procedure get_escheat_payments;

    -- payment processing
    procedure process_echeatment(p_check_id IN number);
    procedure process_installments(p_id IN number);
    procedure delete_installment(p_id IN number);

end escheat_pkg;
