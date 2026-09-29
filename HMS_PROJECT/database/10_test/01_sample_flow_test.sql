/*
================================================================================
 File    : database/10_test/01_sample_flow_test.sql
 Run As  : HMS_APP  (sob install hobar pore)
 Purpose : End-to-end test : Doctor setup -> Patient -> OPD -> Admit ->
           Medicine GRN + Sale -> Discharge.  Sheshe ROLLBACK (data thakbe na).
           Data rakhte chaile sheshe ROLLBACK er jaygay COMMIT likhun.
================================================================================
*/
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
    l_branch   NUMBER;
    l_dept     NUMBER;
    l_desig    NUMBER;
    l_emp      NUMBER;
    l_doc      NUMBER;
    l_pat      NUMBER;
    l_mrn      VARCHAR2(30);
    l_visit    NUMBER;
    l_visit_no VARCHAR2(30);
    l_bill     NUMBER;
    l_rcpt     NUMBER;
    l_bed      NUMBER;
    l_adm      NUMBER;
    l_adm_no   VARCHAR2(30);
    l_item     NUMBER;
    l_store    NUMBER;
    l_sup      NUMBER;
    l_grn      NUMBER;
    l_sale     NUMBER;
    l_ipd_bill NUMBER;
    l_due      NUMBER;
    l_bed_status VARCHAR2(20);
BEGIN
    SELECT BRANCH_ID INTO l_branch FROM HMS_BRANCH WHERE BRANCH_CODE = 'HQ';
    SELECT DEPT_ID INTO l_dept FROM HMS_DEPARTMENT WHERE DEPT_CODE = 'MED' AND BRANCH_ID = l_branch;
    SELECT DESIGNATION_ID INTO l_desig FROM HMS_DESIGNATION WHERE DESIGNATION_CODE = 'CONSULTANT';

    -- 1. Doctor
    INSERT INTO HMS_EMPLOYEE (BRANCH_ID, DEPT_ID, DESIGNATION_ID, EMPLOYEE_CODE, FIRST_NAME, LAST_NAME, GENDER, JOINING_DATE, EMPLOYEE_TYPE)
    VALUES (l_branch, l_dept, l_desig, 'TEST-EMP-1', 'Rahim', 'Uddin', 'MALE', SYSDATE, 'PERMANENT')
    RETURNING EMPLOYEE_ID INTO l_emp;
    INSERT INTO HMS_DOCTOR (EMPLOYEE_ID, DOCTOR_CODE, SPECIALIZATION, BMDC_REG_NO, CONSULTATION_FEE, FOLLOWUP_FEE, DOCTOR_TYPE)
    VALUES (l_emp, 'TEST-DOC-1', 'Medicine', 'A-12345', 1000, 500, 'CONSULTANT')
    RETURNING DOCTOR_ID INTO l_doc;
    DBMS_OUTPUT.PUT_LINE('1. Doctor created       : ' || l_doc);

    -- 2. Patient
    l_pat := PKG_PATIENT.register_patient(l_branch, 'karim', 'hossain', 'MALE', '01711000000',
                                          p_age_years => 45, p_mrn => l_mrn);
    DBMS_OUTPUT.PUT_LINE('2. Patient registered   : ' || l_mrn || ' (id ' || l_pat || ')');

    -- 3. OPD visit + payment
    l_visit := PKG_OPD.create_visit(l_branch, l_pat, l_doc, l_dept, p_visit_no => l_visit_no, p_bill_id => l_bill);
    PKG_OPD.save_vitals(l_visit, 130, 85, 78, 98.6, 98, 70, 170);
    l_rcpt := PKG_BILLING.receive_payment(l_bill, 1000, 'CASH');
    DBMS_OUTPUT.PUT_LINE('3. OPD visit            : ' || l_visit_no || ', bill ' || l_bill || ', due ' || FN_GET_PATIENT_DUE(l_pat));

    -- 4. Admit (first available general bed)
    SELECT MIN(BED_ID) INTO l_bed FROM HMS_BED WHERE BED_STATUS = 'AVAILABLE' AND BED_NO LIKE 'GW-M%';
    l_adm := PKG_IPD.admit_patient(l_branch, l_pat, l_doc, l_dept, l_bed,
                                   p_reason => 'Fever', p_opd_visit_id => l_visit,
                                   p_advance_amount => 10000, p_admission_no => l_adm_no);
    DBMS_OUTPUT.PUT_LINE('4. Admitted             : ' || l_adm_no || ', available beds now ' || FN_GET_AVAILABLE_BEDS);

    -- 5. Medicine: item + supplier + GRN + IPD sale
    SELECT STORE_ID INTO l_store FROM HMS_PHARMA_STORE WHERE STORE_CODE = 'PH-IPD';
    INSERT INTO HMS_PHARMA_ITEM (ITEM_CODE, ITEM_NAME, STRENGTH, PURCHASE_PRICE, MRP, REORDER_LEVEL)
    VALUES ('TEST-NAPA', 'Napa 500mg', '500mg', 0.8, 1.2, 100) RETURNING ITEM_ID INTO l_item;
    INSERT INTO HMS_PHARMA_SUPPLIER (SUPPLIER_CODE, SUPPLIER_NAME) VALUES ('TEST-SUP', 'Test Supplier')
    RETURNING SUPPLIER_ID INTO l_sup;
    l_mrn := FN_GET_NEXT_NO(l_branch, 'GRN');   -- reuse var for GRN no
    INSERT INTO HMS_PHARMA_GRN (GRN_NO, SUPPLIER_ID, STORE_ID) VALUES (l_mrn, l_sup, l_store)
    RETURNING GRN_ID INTO l_grn;
    INSERT INTO HMS_PHARMA_GRN_DTL (GRN_ID, ITEM_ID, BATCH_NO, EXPIRY_DATE, QUANTITY, UNIT_COST, MRP)
    VALUES (l_grn, l_item, 'B001', ADD_MONTHS(SYSDATE, 2), 50, 0.8, 1.2);
    INSERT INTO HMS_PHARMA_GRN_DTL (GRN_ID, ITEM_ID, BATCH_NO, EXPIRY_DATE, QUANTITY, UNIT_COST, MRP)
    VALUES (l_grn, l_item, 'B002', ADD_MONTHS(SYSDATE, 12), 100, 0.8, 1.2);
    PKG_PHARMACY.post_grn(l_grn);

    l_sale := PKG_PHARMACY.create_sale(l_branch, l_store, 'IPD', l_pat, l_adm);
    PKG_PHARMACY.add_sale_item(l_sale, l_item, 60);       -- FEFO: B001 theke 50, B002 theke 10
    PKG_PHARMACY.finalize_sale(l_sale, 0);
    DBMS_OUTPUT.PUT_LINE('5. Pharmacy stock left  : ' || PKG_PHARMACY.get_stock(l_store, l_item) || ' (expected 90)');

    -- 6. Discharge (advance adjust hobe)
    l_ipd_bill := PKG_IPD.get_ipd_bill_id(l_adm);
    PKG_IPD.discharge_patient(l_adm);
    SELECT DUE_AMOUNT INTO l_due FROM HMS_BILLING WHERE BILL_ID = l_ipd_bill;
    DBMS_OUTPUT.PUT_LINE('6. Discharged. IPD due  : ' || l_due);
    SELECT BED_STATUS INTO l_bed_status FROM HMS_BED WHERE BED_ID = l_bed;
    DBMS_OUTPUT.PUT_LINE('   Bed status now       : ' || l_bed_status || ' (expected CLEANING)');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST FAILED: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RAISE;
END;
/

ROLLBACK;
PROMPT Test complete (rolled back).
