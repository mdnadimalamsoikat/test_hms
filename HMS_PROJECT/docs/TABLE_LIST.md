# HMS - Module wise Table List

Auto-generated from `_generator/tables_def.py`.

**Total: 122 tables, 21 modules**


## 01. CORE / MASTER MODULE (Foundation)  
File: `database/02_tables/01_core_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_BRANCH` | BRANCH_ID | Hospital branch / unit |
| 2 | `HMS_DEPARTMENT` | DEPT_ID |  |
| 3 | `HMS_DESIGNATION` | DESIGNATION_ID |  |
| 4 | `HMS_EMPLOYEE` | EMPLOYEE_ID |  |
| 5 | `HMS_EMPLOYEE_QUALIFICATION` | QUALIFICATION_ID |  |
| 6 | `HMS_EMPLOYEE_EXPERIENCE` | EXPERIENCE_ID |  |
| 7 | `HMS_DOCTOR` | DOCTOR_ID |  |
| 8 | `HMS_DOCTOR_DEPT_MAP` | MAP_ID |  |
| 9 | `HMS_DOCTOR_SCHEDULE` | SCHEDULE_ID | START_TIME/END_TIME format HH24:MI (e.g. 17:30) |
| 10 | `HMS_LOOKUP_MASTER` | LOOKUP_ID | Generic dropdown values (Blood group, Religion, Relation ...) |
| 11 | `HMS_SYSTEM_CONFIG` | CONFIG_ID |  |
| 12 | `HMS_NUMBER_SERIES` | SERIES_ID | MRN, Bill No, Visit No, Admission No generate korar jonno |
| 13 | `HMS_ICD_MASTER` | ICD_ID |  |
| 14 | `HMS_SHIFT_MASTER` | SHIFT_ID |  |

## 02. SECURITY MODULE (User, Role, Menu Access)  
File: `database/02_tables/02_security_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_ROLE` | ROLE_ID |  |
| 2 | `HMS_APP_MODULE` | MODULE_ID | Menu / page list |
| 3 | `HMS_ROLE_PERMISSION` | PERMISSION_ID |  |
| 4 | `HMS_USER` | USER_ID |  |
| 5 | `HMS_USER_ROLE` | USER_ROLE_ID |  |
| 6 | `HMS_LOGIN_HISTORY` | LOGIN_ID |  |

## 03. PATIENT MANAGEMENT MODULE  
File: `database/02_tables/03_patient_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_PATIENT` | PATIENT_ID |  |
| 2 | `HMS_PATIENT_ALLERGY` | ALLERGY_ID |  |
| 3 | `HMS_PATIENT_MEDICAL_HISTORY` | HISTORY_ID |  |
| 4 | `HMS_PATIENT_DOCUMENT` | DOCUMENT_ID | REF_TYPE = OPD/IPD/LAB ... , REF_ID = related visit/admission id |

## 04. SERVICE / CHARGE MASTER  
File: `database/02_tables/04_service_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_SERVICE_CATEGORY` | CATEGORY_ID |  |
| 2 | `HMS_SERVICE_MASTER` | SERVICE_ID |  |
| 3 | `HMS_SERVICE_CHARGE` | CHARGE_ID | Category-wise (GENERAL/VIP/CORPORATE) rate |
| 4 | `HMS_SERVICE_PACKAGE_DTL` | PACKAGE_DTL_ID |  |
| 5 | `HMS_DOCTOR_COMMISSION` | COMMISSION_ID | Referral / consultation commission setup |

## 05. APPOINTMENT & SCHEDULING  
File: `database/02_tables/05_appointment_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_APPOINTMENT` | APPOINTMENT_ID |  |
| 2 | `HMS_COMMUNICATION_LOG` | COMM_ID |  |

## 06. OPD (Out Patient Department)  
File: `database/02_tables/06_opd_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_OPD_VISIT` | VISIT_ID |  |
| 2 | `HMS_OPD_VITALS` | VITAL_ID |  |
| 3 | `HMS_OPD_CONSULTATION` | CONSULTATION_ID |  |
| 4 | `HMS_OPD_PRESCRIPTION` | PRESCRIPTION_ID |  |
| 5 | `HMS_OPD_PRESCRIPTION_DTL` | PRESCRIPTION_DTL_ID | FREQUENCY e.g. 1+0+1 |
| 6 | `HMS_OPD_PROCEDURE` | OPD_PROC_ID |  |

## 07. IPD (In Patient Department)  
File: `database/02_tables/07_ipd_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_WARD` | WARD_ID |  |
| 2 | `HMS_BED` | BED_ID |  |
| 3 | `HMS_IPD_ADMISSION` | ADMISSION_ID |  |
| 4 | `HMS_BED_TRANSFER` | TRANSFER_ID |  |
| 5 | `HMS_IPD_DOCTOR_VISIT` | IPD_VISIT_ID |  |
| 6 | `HMS_IPD_MEDICATION` | MEDICATION_ID | Doctor medication order (chart) |
| 7 | `HMS_IPD_MED_ADMINISTRATION` | ADMIN_ID | Nurse medication administration record (MAR) |
| 8 | `HMS_DISCHARGE_SUMMARY` | SUMMARY_ID |  |

## 08. DIAGNOSTIC & LABORATORY  
File: `database/02_tables/08_lab_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_INVESTIGATION_ORDER` | ORDER_ID |  |
| 2 | `HMS_INVESTIGATION_ORDER_DTL` | ORDER_DTL_ID |  |
| 3 | `HMS_LAB_PARAMETER` | PARAMETER_ID |  |
| 4 | `HMS_LAB_REFERENCE_RANGE` | RANGE_ID |  |
| 5 | `HMS_LAB_SAMPLE` | SAMPLE_ID | Barcode = SAMPLE_NO |
| 6 | `HMS_LAB_EQUIPMENT` | EQUIPMENT_ID |  |
| 7 | `HMS_LAB_RESULT` | RESULT_ID |  |
| 8 | `HMS_LAB_RESULT_AMENDMENT` | AMENDMENT_ID |  |

## 09. RADIOLOGY / IMAGING  
File: `database/02_tables/09_radiology_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_RADIOLOGY_ORDER` | RAD_ORDER_ID |  |
| 2 | `HMS_RADIOLOGY_IMAGE` | IMAGE_ID |  |
| 3 | `HMS_REPORT_TEMPLATE` | TEMPLATE_ID | Radiology / USG report template |

## 10. PHARMACY  
File: `database/02_tables/10_pharmacy_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_PHARMA_CATEGORY` | PH_CATEGORY_ID | Tablet, Capsule, Syrup, Injection ... |
| 2 | `HMS_PHARMA_GENERIC` | GENERIC_ID |  |
| 3 | `HMS_PHARMA_MANUFACTURER` | MANUFACTURER_ID |  |
| 4 | `HMS_PHARMA_ITEM` | ITEM_ID |  |
| 5 | `HMS_PHARMA_SUPPLIER` | SUPPLIER_ID |  |
| 6 | `HMS_PHARMA_STORE` | STORE_ID |  |
| 7 | `HMS_PHARMA_PURCHASE_ORDER` | PO_ID |  |
| 8 | `HMS_PHARMA_PO_DTL` | PO_DTL_ID |  |
| 9 | `HMS_PHARMA_GRN` | GRN_ID | Goods Receive Note |
| 10 | `HMS_PHARMA_GRN_DTL` | GRN_DTL_ID |  |
| 11 | `HMS_PHARMA_STOCK` | STOCK_ID |  |
| 12 | `HMS_PHARMA_SALE` | SALE_ID |  |
| 13 | `HMS_PHARMA_SALE_DTL` | SALE_DTL_ID |  |
| 14 | `HMS_PHARMA_SALE_RETURN` | RETURN_ID |  |
| 15 | `HMS_PHARMA_TRANSACTION` | TXN_ID | Stock ledger (sob movement ekhane log hobe) |

## 11. OPERATION THEATRE (OT)  
File: `database/02_tables/11_ot_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_OT_MASTER` | OT_ID |  |
| 2 | `HMS_SURGERY_MASTER` | SURGERY_ID |  |
| 3 | `HMS_OT_BOOKING` | BOOKING_ID |  |
| 4 | `HMS_OT_TEAM` | TEAM_ID |  |
| 5 | `HMS_OT_NOTES` | OT_NOTE_ID |  |
| 6 | `HMS_OT_CONSUMABLE` | CONSUMABLE_ID |  |

## 12. BLOOD BANK  
File: `database/02_tables/12_blood_bank_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_BLOOD_DONOR` | DONOR_ID |  |
| 2 | `HMS_BLOOD_COLLECTION` | COLLECTION_ID |  |
| 3 | `HMS_BLOOD_INVENTORY` | BLOOD_STOCK_ID |  |
| 4 | `HMS_BLOOD_REQUISITION` | REQUISITION_ID |  |
| 5 | `HMS_BLOOD_CROSSMATCH` | CROSSMATCH_ID |  |
| 6 | `HMS_BLOOD_ISSUE` | ISSUE_ID |  |

## 13. NURSING  
File: `database/02_tables/13_nursing_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_NURSING_ASSESSMENT` | ASSESSMENT_ID |  |
| 2 | `HMS_IPD_VITALS` | IPD_VITAL_ID |  |
| 3 | `HMS_NURSING_CARE_PLAN` | CARE_PLAN_ID |  |
| 4 | `HMS_NURSING_NOTES` | NOTE_ID |  |

## 14. DIET / KITCHEN  
File: `database/02_tables/14_diet_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_DIET_MASTER` | DIET_ID |  |
| 2 | `HMS_DIET_ORDER` | DIET_ORDER_ID |  |
| 3 | `HMS_DIET_SERVING` | SERVING_ID |  |

## 15. INSURANCE / TPA / CORPORATE  
File: `database/02_tables/15_insurance_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_INSURANCE_COMPANY` | INS_COMPANY_ID |  |
| 2 | `HMS_INSURANCE_PLAN` | PLAN_ID |  |
| 3 | `HMS_PATIENT_INSURANCE` | POLICY_ID |  |
| 4 | `HMS_INSURANCE_PREAUTH` | PREAUTH_ID |  |

## 16. ACCOUNT & BILLING  
File: `database/02_tables/16_billing_accounts_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_BILLING` | BILL_ID |  |
| 2 | `HMS_BILLING_DTL` | BILL_DTL_ID | REF_TYPE = LAB_ORDER_DTL / PHARMA_SALE / BED / OT_BOOKING ... |
| 3 | `HMS_PATIENT_ADVANCE` | ADVANCE_ID |  |
| 4 | `HMS_PAYMENT_RECEIPT` | RECEIPT_ID |  |
| 5 | `HMS_INSURANCE_CLAIM` | CLAIM_ID |  |
| 6 | `HMS_DOCTOR_EARNING` | EARNING_ID |  |
| 7 | `HMS_CHART_OF_ACCOUNTS` | COA_ID |  |
| 8 | `HMS_JOURNAL_VOUCHER` | VOUCHER_ID |  |
| 9 | `HMS_JOURNAL_VOUCHER_DTL` | VOUCHER_DTL_ID |  |

## 17. INVENTORY & STORE (General items + Asset)  
File: `database/02_tables/17_inventory_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_INV_STORE` | INV_STORE_ID |  |
| 2 | `HMS_INV_ITEM` | INV_ITEM_ID |  |
| 3 | `HMS_INV_STOCK` | INV_STOCK_ID |  |
| 4 | `HMS_INDENT` | INDENT_ID | Department requisition |
| 5 | `HMS_INDENT_DTL` | INDENT_DTL_ID |  |
| 6 | `HMS_ASSET` | ASSET_ID |  |

## 18. ADMIN / HR / PAYROLL  
File: `database/02_tables/18_hr_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_DUTY_ROSTER` | ROSTER_ID |  |
| 2 | `HMS_ATTENDANCE` | ATTENDANCE_ID |  |
| 3 | `HMS_LEAVE_TYPE` | LEAVE_TYPE_ID |  |
| 4 | `HMS_LEAVE_APPLICATION` | LEAVE_ID |  |
| 5 | `HMS_SALARY_STRUCTURE` | SALARY_ID |  |
| 6 | `HMS_PAYROLL` | PAYROLL_ID | SALARY_MONTH format YYYY-MM |

## 19. EMERGENCY & AMBULANCE  
File: `database/02_tables/19_emergency_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_EMERGENCY_VISIT` | ER_VISIT_ID |  |
| 2 | `HMS_EMERGENCY_TRIAGE` | TRIAGE_ID |  |
| 3 | `HMS_AMBULANCE` | AMBULANCE_ID |  |
| 4 | `HMS_AMBULANCE_TRIP` | TRIP_ID |  |

## 20. MORTUARY  
File: `database/02_tables/20_mortuary_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_MORTUARY` | MORTUARY_ID |  |

## 21. AUDIT & SECURITY LOG  
File: `database/02_tables/21_audit_tables.sql`

| # | Table | Primary Key | Description |
|---|---|---|---|
| 1 | `HMS_AUDIT_TRAIL` | AUDIT_ID |  |
| 2 | `HMS_ERROR_LOG` | ERROR_ID |  |
