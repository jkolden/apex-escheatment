create or replace package body escheat_pkg is

    ------------------------------------------------------------------------
    -- Internal helpers
    ------------------------------------------------------------------------

    function trim_to_xml(p_clob IN clob) return xmltype is
        l_position number;
    begin
        l_position := instr(p_clob, '<');
        if l_position = 0 then
            raise_application_error(-20001, 'No XML content found in response');
        end if;
        return xmltype.createXML(substr(p_clob, l_position));
    end trim_to_xml;

    function get_otbi_session return varchar2 is
        l_envelope         clob;
        l_response_clob    clob;
        l_xml              xmltype;
        l_session_id       varchar2(120);
    begin
        l_envelope :=
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v6="urn://oracle.bi.webservices/v6">'
            || '<soapenv:Header/>'
            || '<soapenv:Body>'
            || '  <v6:logon>'
            || '    <v6:name>' || g_user || '</v6:name>'
            || '    <v6:password>' || nvl(g_password, '') || '</v6:password>'
            || '  </v6:logon>'
            || '</soapenv:Body>'
            || '</soapenv:Envelope>';

        apex_web_service.g_request_headers(1).name  := 'SOAPAction';
        apex_web_service.g_request_headers(1).value := '#logon';
        apex_web_service.g_request_headers(2).name  := 'Content-Type';
        apex_web_service.g_request_headers(2).value := 'text/xml; charset=UTF-8';

        l_response_clob := apex_web_service.make_rest_request(
            p_url         => 'https://' || g_instance || g_domain || '/analytics-ws/saw.dll?SoapImpl=nQSessionService',
            p_http_method => 'POST',
            p_body        => l_envelope
        );

        if apex_web_service.g_status_code not in (200, 201) then
            raise_application_error(-20002, 'OTBI logon failed: ' || apex_web_service.g_status_code);
        end if;

        l_xml := trim_to_xml(l_response_clob);

        select data
        into   l_session_id
        from   XMLTable(
                 XMLNamespaces(
                   'http://schemas.xmlsoap.org/soap/envelope/' AS "SOAP-ENV",
                   'urn://oracle.bi.webservices/v6' AS "sawsoap"
                 ),
                 'SOAP-ENV:Envelope/SOAP-ENV:Body/sawsoap:logonResult'
                 passing l_xml
                 columns data clob path '.'
               );

        return l_session_id;
    end get_otbi_session;

    function execute_otbi_query(p_sql IN clob, p_session_id IN varchar2) return xmltype is
        l_envelope      clob;
        l_response_clob clob;
        l_xml           xmltype;
    begin
        l_envelope :=
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v6="urn://oracle.bi.webservices/v6">'
            || '<soapenv:Header/>'
            || '<soapenv:Body>'
            || '  <v6:executeSQLQuery>'
            || '    <v6:sql>' || p_sql || '</v6:sql>'
            || '    <v6:outputFormat></v6:outputFormat>'
            || '    <v6:executionOptions>'
            || '      <v6:async></v6:async>'
            || '      <v6:maxRowsPerPage></v6:maxRowsPerPage>'
            || '      <v6:refresh>true</v6:refresh>'
            || '      <v6:presentationInfo>false</v6:presentationInfo>'
            || '      <v6:type></v6:type>'
            || '    </v6:executionOptions>'
            || '    <v6:sessionID>' || p_session_id || '</v6:sessionID>'
            || '  </v6:executeSQLQuery>'
            || '</soapenv:Body>'
            || '</soapenv:Envelope>';

        apex_web_service.g_request_headers(1).name  := 'SOAPAction';
        apex_web_service.g_request_headers(1).value := '#executeSQLQuery';
        apex_web_service.g_request_headers(2).name  := 'Content-Type';
        apex_web_service.g_request_headers(2).value := 'text/xml; charset=UTF-8';

        l_response_clob := apex_web_service.make_rest_request(
            p_url         => 'https://' || g_instance || g_domain || '/analytics-ws/saw.dll?SoapImpl=xmlViewService',
            p_http_method => 'POST',
            p_body        => l_envelope
        );

        if apex_web_service.g_status_code not in (200, 201) then
            raise_application_error(-20003, 'OTBI query failed: ' || apex_web_service.g_status_code);
        end if;

        l_xml := trim_to_xml(l_response_clob);
        return l_xml;
    end execute_otbi_query;

    -- get_receivables_invoices removed (not used by the APEX app)

    procedure get_invoice_installments is
        l_xml        xmltype;
        l_session_id varchar2(120);
        l_sql        clob :=
            'SELECT 0 s_0,'
            || ' "Payables Invoices - Installments Real Time"."- General Information"."Invoice Date" s_1,'
            || ' "Payables Invoices - Installments Real Time"."- General Information"."Invoice ID" s_2,'
            || ' "Payables Invoices - Installments Real Time"."- General Information"."Invoice Number" s_3,'
            || ' "Payables Invoices - Installments Real Time"."- General Information"."Terms Date" s_4,'
            || ' "Payables Invoices - Installments Real Time"."Business Unit"."Business Unit Name" s_5,'
            || ' "Payables Invoices - Installments Real Time"."Invoices Installment Details"."Payment Number" s_6,'
            || ' "Payables Invoices - Installments Real Time"."Invoices Installment Details"."Payment Status Flag" s_7,'
            || ' "Payables Invoices - Installments Real Time"."Supplier Site"."Supplier Site Name" s_8,'
            || ' "Payables Invoices - Installments Real Time"."Supplier"."Supplier Name" s_9,'
            || ' "Payables Invoices - Installments Real Time"."Supplier"."Supplier Number" s_10,'
            || ' "Payables Invoices - Installments Real Time"."Supplier"."Tax Payer ID" s_11,'
            || ' DESCRIPTOR_IDOF("Payables Invoices - Installments Real Time"."Business Unit"."Business Unit Name") s_12,'
            || ' "Payables Invoices - Installments Real Time"."Invoices Installment Amounts"."Gross Amount" s_13'
            || ' FROM "Payables Invoices - Installments Real Time"'
            || ' WHERE ((DESCRIPTOR_IDOF("Payables Invoices - Installments Real Time"."Business Unit"."Business Unit Name") = 300000075888561)'
            || ' AND ("Invoices Installment Details"."Payment Status Flag" = ''N'')'
            || ' AND ("- General Information"."Invoice Date" > date ''2021-01-01''))'
            || ' ORDER BY 1, 2 DESC NULLS FIRST, 6 ASC NULLS LAST, 10 ASC NULLS LAST, 11 ASC NULLS LAST, 12 ASC NULLS LAST, 9 ASC NULLS LAST, 4 ASC NULLS LAST, 3 ASC NULLS LAST, 5 ASC NULLS LAST, 7 ASC NULLS LAST, 8 ASC NULLS LAST'
            || ' FETCH FIRST 75001 ROWS ONLY';
    begin

        l_session_id := get_otbi_session();
        l_xml := execute_otbi_query(l_sql, l_session_id);

        merge into com_invoices d
        using (
            select r.invoice_date,
                   r.terms_date,
                   r.invoice_id,
                   r.installment_number,
                   r.supplier_name,
                   r.taxpayer_id,
                   r.invoice_number,
                   r.gross_amount,
                   r.payment_status,
                   r.address_name,
                   r.supplier_number
            from XMLTable(
                     XMLNamespaces(
                       'http://schemas.xmlsoap.org/soap/envelope/' AS "SOAP-ENV",
                       'urn://oracle.bi.webservices/v6' AS "sawsoap"
                     ),
                     'SOAP-ENV:Envelope/SOAP-ENV:Body/sawsoap:executeSQLQueryResult/sawsoap:return/sawsoap:rowset'
                     passing l_xml
                     columns Row1 clob path '.'
                 ) rowset,
                 XMLTable(
                     '/*/Row'
                     passing xmlparse(document regexp_replace(rowset.Row1, 'xmlns=".*"', ''))
                     columns
                         invoice_date      PATH 'Column1',
                         invoice_id        PATH 'Column2',
                         invoice_number    PATH 'Column3',
                         terms_date        PATH 'Column4',
                         installment_number PATH 'Column6',
                         payment_status    PATH 'Column7',
                         address_name      PATH 'Column8',
                         supplier_name     PATH 'Column9',
                         supplier_number   PATH 'Column10',
                         taxpayer_id       PATH 'Column11',
                         gross_amount      PATH 'Column13'
                 ) r
        ) s
        on (d.invoice_id = s.invoice_id and d.installment_number = s.installment_number)
        when not matched then
            insert (d.id, d.invoice_date, d.terms_date, d.invoice_id, d.installment_number, d.supplier_name, d.taxpayer_id, d.invoice_number, d.gross_amount, d.payment_status, d.address_name, d.supplier_number)
            values (generic_seq.nextval, to_date(s.invoice_date, 'YYYY-MM-DD'), to_date(s.terms_date, 'YYYY-MM-DD'), s.invoice_id, s.installment_number, s.supplier_name, s.taxpayer_id, s.invoice_number, s.gross_amount, s.payment_status, s.address_name, s.supplier_number);
    end get_invoice_installments;

    procedure get_escheat_payments is
        l_xml        xmltype;
        l_session_id varchar2(120);
        l_sql        clob :=
            'SELECT 0 s_0,'
            || ' "Payables Payments - Disbursements Real Time"."- General Information"."Invoice Date" s_1,'
            || ' "Payables Payments - Disbursements Real Time"."- General Information"."Invoice Number" s_2,'
            || ' "Payables Payments - Disbursements Real Time"."- Other Information"."Recon Flag" s_3,'
            || ' "Payables Payments - Disbursements Real Time"."- Payment Information"."Check Date" s_4,'
            || ' "Payables Payments - Disbursements Real Time"."- Payment Information"."Check Number" s_5,'
            || ' "Payables Payments - Disbursements Real Time"."Business Unit"."Business Unit Name" s_6,'
            || ' "Payables Payments - Disbursements Real Time"."Supplier Site"."Supplier Site Code" s_7,'
            || ' "Payables Payments - Disbursements Real Time"."Supplier Site"."Supplier Site Name" s_8,'
            || ' "Payables Payments - Disbursements Real Time"."Supplier"."Supplier Name" s_9,'
            || ' "Payables Payments - Disbursements Real Time"."Business Unit"."Business Unit Name" s_10,'
            || ' "Payables Payments - Disbursements Real Time"."- Payment Amounts"."Payment Amount" s_11,'
            || ' "Payables Payments - Disbursements Real Time"."- General Information"."Invoice ID" s_12,'
            || ' "Payables Payments - Disbursements Real Time"."- Payment Information"."Check ID" s_13,'
            || ' "Payables Payments - Disbursements Real Time"."Supplier"."Supplier Number" s_14,'
            || ' "Payables Payments - Disbursements Real Time"."- Payment Information"."Payment Status" s_15'
            || ' FROM "Payables Payments - Disbursements Real Time"'
            || ' WHERE ("Payables Payments - Disbursements Real Time"."- Other Information"."Recon Flag" = ''N'''
            || ' AND ("- General Information"."Invoice Date" > date ''2017-11-01'')'
            || ' AND (DESCRIPTOR_IDOF("Payables Payments - Disbursements Real Time"."- Payment Information"."Payment Status") IN (''NEGOTIABLE'', ''VOIDED'')))'
            || ' FETCH FIRST 7500 ROWS ONLY';
    begin

        l_session_id := get_otbi_session();
        l_xml := execute_otbi_query(l_sql, l_session_id);

        merge into escheat_payments d
        using (
            select r.invoice_date,
                   r.invoice_id,
                   r.invoice_number,
                   r.check_id,
                   r.payment_amount,
                   r.supplier_name,
                   r.supplier_site_name,
                   r.check_number,
                   to_date(r.check_date, 'YYYY-MM-DD') check_date,
                   r.supplier_number,
                   r.bu_name,
                   r.payment_status,
                   r.supplier_id,
                   r.supplier_site_id
            from XMLTable(
                     XMLNamespaces(
                       'http://schemas.xmlsoap.org/soap/envelope/' AS "SOAP-ENV",
                       'urn://oracle.bi.webservices/v6' AS "sawsoap"
                     ),
                     'SOAP-ENV:Envelope/SOAP-ENV:Body/sawsoap:executeSQLQueryResult/sawsoap:return/sawsoap:rowset'
                     passing l_xml
                     columns Row1 clob path '.'
                 ) rowset,
                 XMLTable(
                     '/*/Row'
                     passing xmlparse(document regexp_replace(rowset.Row1, 'xmlns=".*"', ''))
                     columns
                         invoice_date       PATH 'Column1',
                         invoice_number     PATH 'Column2',
                         check_id           PATH 'Column13',
                         payment_amount     PATH 'Column11',
                         supplier_name      PATH 'Column9',
                         supplier_site_name PATH 'Column8',
                         check_number       PATH 'Column5',
                         check_date         PATH 'Column4',
                         supplier_number    PATH 'Column14',
                         bu_name            PATH 'Column10',
                         payment_status     PATH 'Column15',
                         supplier_id        PATH 'Column16',
                         supplier_site_id   PATH 'Column17'
                 ) r
        ) s
        on (d.invoice_id = s.invoice_id and d.check_id = s.check_id)
        when matched then
            update set d.payment_status = s.payment_status
        when not matched then
            insert (d.invoice_id, d.invoice_date, d.invoice_number, d.check_id, d.payment_amount, d.supplier_name, d.supplier_site_name, d.check_number, d.check_date, d.supplier_number, d.bu_name, d.payment_status, d.supplier_id, d.supplier_site_id)
            values (s.invoice_id, s.invoice_date, s.invoice_number, s.check_id, s.payment_amount, s.supplier_name, s.supplier_site_name, s.check_number, s.check_date, s.supplier_number, s.bu_name, s.payment_status, s.supplier_id, s.supplier_site_id);
    end get_escheat_payments;

    -- get_bek_escheat_payments removed (not used by the APEX app)

    -- OTBI bulk report procedures removed (not used by the APEX app)

    ------------------------------------------------------------------------
    -- REST helpers
    ------------------------------------------------------------------------

    procedure log_api_results(p_action IN varchar2, p_api_fire_date IN date, p_api IN varchar2, p_status_code IN number, p_response_payload IN clob default null) is
    begin
        insert into com_api_log (batch_id, seq_id, action, api_fire_date, api, status_code, response_payload)
        values (g_batch_id, api_seq.nextval, p_action, p_api_fire_date, p_api, p_status_code, p_response_payload);
    end log_api_results;

    procedure void_payment(p_check_id IN number) is
        l_url varchar2(400);
        l_patch_payload clob;
        l_response clob;
        l_void_date varchar2(10);
    begin
        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/payablesPayments/' || p_check_id;
        l_void_date := to_char(sysdate, 'YYYY-MM-DD');

        apex_json.initialize_clob_output;
        apex_json.open_object;
            apex_json.write('VoidDate', l_void_date);
            apex_json.write('VoidAccountingDate', l_void_date);
        apex_json.close_object;
        l_patch_payload := apex_json.get_clob_output;
        apex_json.free_output;

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
            p_body        => l_patch_payload,
            p_username    => g_payables_user,
            p_password    => g_password
        );

        if apex_web_service.g_status_code = 200 then
            update escheat_payments set void_date = sysdate where check_id = p_check_id;
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'Void Payment', p_status_code => apex_web_service.g_status_code);
        else
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'Void Payment', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;
    end void_payment;

    procedure update_invoice_header(p_invoice_id IN number, p_invoice_amount IN number) is
        l_url varchar2(400);
        l_post_payload clob;
        l_response clob;
    begin
        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/invoices/' || p_invoice_id;

        apex_json.initialize_clob_output;
        apex_json.open_object;
            apex_json.write('InvoiceAmount', p_invoice_amount);
        apex_json.close_object;
        l_post_payload := apex_json.get_clob_output;
        apex_json.free_output;

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'PATCH',
            p_body        => l_post_payload,
            p_username    => g_payables_user,
            p_password    => g_password
        );

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'update invoice header', p_status_code => apex_web_service.g_status_code);
        else
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'update invoice header', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;
    end update_invoice_header;

    procedure create_invoice_line(p_id IN number) is
        l_invoice_id number;
        l_url varchar2(400);
        l_post_payload clob;
        l_response clob;
    begin
        select invoice_id into l_invoice_id from com_invoices where id = p_id;
        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/invoices/' || l_invoice_id || '/child/invoiceLines';

        apex_json.initialize_clob_output;
        apex_json.open_object;
            apex_json.write('LineNumber', 2);
            apex_json.write('LineAmount', -15);
            apex_json.write('Description', 'Automated Intercept Fee');
            apex_json.write('DistributionCombination', '1150-2022-92340-44760-1000-0000-00000000');
        apex_json.close_object;
        l_post_payload := apex_json.get_clob_output;
        apex_json.free_output;

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'POST',
            p_body        => l_post_payload,
            p_username    => g_payables_user,
            p_password    => g_password
        );

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'POST', p_api_fire_date => sysdate, p_api => 'create invoice line', p_status_code => apex_web_service.g_status_code);
            merge into com_remittance_fees d
            using (select l_invoice_id invoice_id, 1 installment_number, -15 amount, sysdate creation_date from dual) s
            on (d.invoice_id = s.invoice_id and d.installment_number = s.installment_number)
            when not matched then
                insert (d.id, d.invoice_id, d.installment_number, d.amount, d.creation_date)
                values (generic_seq.nextval, s.invoice_id, s.installment_number, s.amount, s.creation_date);
        else
            log_api_results(p_action => 'POST', p_api_fire_date => sysdate, p_api => 'create invoice line', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;
    end create_invoice_line;

    function get_supplier_id(p_supplier_number IN varchar2) return number is
        l_response clob;
        l_supplier_id number;
        l_url varchar2(400);
        l_param_names apex_application_global.vc_arr2;
        l_param_values apex_application_global.vc_arr2;
    begin
        l_param_names(1)  := 'q';
        l_param_values(1) := 'SupplierNumber=' || p_supplier_number;

        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/suppliers';

        apex_web_service.g_request_headers(1).name  := 'REST-Framework-Version';
        apex_web_service.g_request_headers(1).value := 2;

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET',
            p_parm_name   => l_param_names,
            p_parm_value  => l_param_values,
            p_username    => g_purchasing_user,
            p_password    => g_password
        );

        select json_value(l_response, '$.items[0].SupplierId') into l_supplier_id from dual;

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'GET', p_api_fire_date => sysdate, p_api => 'get supplier id', p_status_code => apex_web_service.g_status_code, p_response_payload => to_char(l_supplier_id));
        else
            log_api_results(p_action => 'GET', p_api_fire_date => sysdate, p_api => 'get supplier id', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;

        return l_supplier_id;
    end get_supplier_id;

    function get_supplier_site_id(p_supplier_id IN number) return number is
        l_response clob;
        l_supplier_site_id number;
        l_url varchar2(400);
    begin
        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/suppliers/' || p_supplier_id || '/child/sites';

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET',
            p_username    => g_purchasing_user,
            p_password    => g_password
        );

        select json_value(l_response, '$.items[0].SupplierSiteId') into l_supplier_site_id from dual;

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'GET', p_api_fire_date => sysdate, p_api => 'get supplier site id', p_status_code => apex_web_service.g_status_code, p_response_payload => to_char(l_supplier_site_id));
        else
            log_api_results(p_action => 'GET', p_api_fire_date => sysdate, p_api => 'get supplier site id', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;

        return l_supplier_site_id;
    end get_supplier_site_id;

    procedure create_relationship(p_supplier_id IN number, p_supplier_site_id IN number, p_check_date IN date) is
        l_url varchar2(400);
        l_post_payload clob;
        l_response clob;
        l_date varchar2(10);
    begin
        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/suppliers/' || p_supplier_id || '/child/sites/' || p_supplier_site_id || '/child/thirdPartyPaymentRelationships';
        l_date := to_char(p_check_date, 'YYYY-MM-DD');

        apex_json.initialize_clob_output;
        apex_json.open_object;
            apex_json.write('RemitToSupplier', 'City of Boston');
            apex_json.write('RemitToAddress', 'Main');
            apex_json.write('FromDate', l_date);
            apex_json.write('ToDate', l_date);
            apex_json.write('Description', 'Third party relationship');
            apex_json.write('DefaultRelationshipFlag', 'true');
        apex_json.close_object;
        l_post_payload := apex_json.get_clob_output;
        apex_json.free_output;

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'POST',
            p_body        => l_post_payload,
            p_username    => g_purchasing_user,
            p_password    => g_password
        );

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'POST', p_api_fire_date => sysdate, p_api => 'create third party relationship', p_status_code => apex_web_service.g_status_code);
        else
            log_api_results(p_action => 'POST', p_api_fire_date => sysdate, p_api => 'create third party relationship', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;
    end create_relationship;

    function get_installment_url(p_invoice_id IN number) return varchar2 is
        l_url varchar2(400);
        l_response clob;
        l_installment_url varchar2(400);
    begin
        l_url := 'https://' || g_instance || '-saasfademo1.ds-fa.oraclepdemos.com/fscmRestApi/resources/11.13.18.05/invoices/' || p_invoice_id || '/child/invoiceInstallments';

        l_response := apex_web_service.make_rest_request(
            p_url         => l_url,
            p_http_method => 'GET',
            p_username    => g_payables_user,
            p_password    => g_password
        );

        select json_value(l_response, '$.items[0].links[0].href') into l_installment_url from dual;

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'GET', p_api_fire_date => sysdate, p_api => 'get installment', p_status_code => apex_web_service.g_status_code, p_response_payload => l_installment_url);
        else
            log_api_results(p_action => 'GET', p_api_fire_date => sysdate, p_api => 'get installment', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;

        return l_installment_url;
    end get_installment_url;

    procedure update_existing_installment(p_url IN varchar2) is
        l_patch_payload clob;
        l_response clob;
    begin
        apex_json.initialize_clob_output;
        apex_json.open_object;
            apex_json.write('RemitToSupplier', 'City of Boston');
            apex_json.write('RemitToAddressName', 'Main');
            apex_json.write('BankAccount', '');
        apex_json.close_object;
        l_patch_payload := apex_json.get_clob_output;
        apex_json.free_output;

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => p_url,
            p_http_method => 'PATCH',
            p_body        => l_patch_payload,
            p_username    => g_payables_user,
            p_password    => g_password
        );

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'update installment', p_status_code => apex_web_service.g_status_code);
        else
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'update installment', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;
    end update_existing_installment;

    procedure update_offset_installment(p_url IN varchar2, p_amount IN number) is
        l_patch_payload clob;
        l_response clob;
    begin
        apex_json.initialize_clob_output;
        apex_json.open_object;
            apex_json.write('RemitToSupplier', 'City of Boston');
            apex_json.write('RemitToAddressName', 'Main');
            apex_json.write('GrossAmount', p_amount);
            apex_json.write('BankAccount', '');
        apex_json.close_object;
        l_patch_payload := apex_json.get_clob_output;
        apex_json.free_output;

        apex_web_service.g_request_headers(1).name  := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';

        l_response := apex_web_service.make_rest_request(
            p_url         => p_url,
            p_http_method => 'PATCH',
            p_body        => l_patch_payload,
            p_username    => g_payables_user,
            p_password    => g_password
        );

        if apex_web_service.g_status_code in (200, 201) then
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'update installment', p_status_code => apex_web_service.g_status_code);
        else
            log_api_results(p_action => 'PATCH', p_api_fire_date => sysdate, p_api => 'update installment', p_status_code => apex_web_service.g_status_code, p_response_payload => l_response);
        end if;
    end update_offset_installment;

    procedure delete_installment(p_id IN number) is
        l_invoice_id number;
        l_response clob;
        l_url varchar2(400);
        l_installment_url varchar2(400);
    begin
        select invoice_id into l_invoice_id from com_invoices where id = p_id;

        l_url := 'https://' || g_instance || g_domain || '/fscmRestApi/resources/11.13.18.05/invoices/' || l_invoice_id || '/child/invoiceInstallments';

        l_response := apex_web_service.make_rest_request(
            p_url          => l_url,
            p_http_method  => 'GET',
            p_username => g_payables_user,
            p_password => g_password
          );

        select json_value(l_response, '$.items[1].links[0].href') into l_installment_url from dual;

        l_response := apex_web_service.make_rest_request(
            p_url          => l_installment_url,
            p_http_method  => 'DELETE',
            p_username => g_payables_user,
            p_password => g_password
          );

          IF apex_web_service.g_status_code IN (204) THEN
            log_api_results(p_action => 'DELETE', p_api_fire_date => sysdate, p_api => 'delete installment', p_status_code => apex_web_service.g_status_code);
        ELSE
            log_api_results(p_action => 'DELETE', p_api_fire_date => sysdate, p_api => 'delete installment', p_status_code => apex_web_service.g_status_code, p_response_payload =>
            l_response);
        END IF;
    end delete_installment;

    procedure process_echeatment(p_check_id IN number) is
        l_supplier_number varchar2(25);
        l_supplier_id number;
        l_supplier_site_id number;
        l_installment_url varchar2(400);
        l_check_date date;
    begin
        g_batch_id := api_batch_seq.nextval;

        select check_date, supplier_number into l_check_date, l_supplier_number from escheat_payments where check_id = p_check_id;
        update escheat_payments set batch_id = g_batch_id where check_id = p_check_id;

        void_payment(p_check_id => p_check_id);

        l_supplier_id := get_supplier_id(p_supplier_number => l_supplier_number);
        l_supplier_site_id := get_supplier_site_id(p_supplier_id => l_supplier_id);
        create_relationship(p_supplier_id => l_supplier_id, p_supplier_site_id => l_supplier_site_id, p_check_date => l_check_date);

        select invoice_id into l_invoice_id from escheat_payments where check_id = p_check_id;
        l_installment_url := get_installment_url(p_invoice_id => l_invoice_id);
        update_existing_installment(p_url => l_installment_url);
    end process_echeatment;

    procedure process_installments(p_id IN number) is
        l_invoice_id number;
        l_supplier_id number;
        l_supplier_site_id number;
        l_supplier_number varchar2(25);
        l_installment_url varchar2(400);
        l_invoice_date date;
        l_invoice_amount number;
    begin
        g_batch_id := api_batch_seq.nextval;
        select invoice_date, gross_amount, invoice_id, supplier_number into l_invoice_date, l_invoice_amount, l_invoice_id, l_supplier_number from com_invoices where id = p_id;

        update_invoice_header(p_invoice_id => l_invoice_id, p_invoice_amount => (l_invoice_amount - 15));
        create_invoice_line(p_id => p_id);

        l_supplier_id := get_supplier_id(p_supplier_number => l_supplier_number);
        l_supplier_site_id := get_supplier_site_id(p_supplier_id => l_supplier_id);
        create_relationship(p_supplier_id => l_supplier_id, p_supplier_site_id => l_supplier_site_id, p_check_date => l_invoice_date);

        l_installment_url := get_installment_url(p_invoice_id => l_invoice_id);
        update_offset_installment(p_url => l_installment_url, p_amount => l_invoice_amount - 15);

        update com_invoices set batch_id = g_batch_id where id = p_id;
    end process_installments;

end escheat_pkg;
