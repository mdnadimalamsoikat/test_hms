# SPRINT 7 — Laboratory (Page 50, 51, 54, 52, 53)

🎯 **Ei sprint e ki hobe:** Lab test order → sample → result → verify → report.

## Shuru-r age (check)
- [ ] DB: `02_pkg_lab.sql`, `03_apex_views.sql` run
- [ ] Sprint 3: Lab service + test parameter + reference range
- [ ] Sprint 5 (lab bill)

**Build order:** 50 → 51 → 511 → 54 → 52 → 53

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Flow: **Order (50)** → Bill/Pay (71) → **Sample (51)** → **Worklist (54)** → **Result (52)** → Verify → **Report (53)**
Package: `PKG_LAB` (11_apex_support/02_pkg_lab.sql). Item status: ORDERED → SAMPLE_COLLECTED → RESULT_ENTERED → VERIFIED.

---
## PAGE 50 — Lab Order Entry
Blank 50 ▸ Authorization AUTH_LAB_ADD.
| Region | Span | Items |
|---|---|---|
| Patient | 12 | P50_PATIENT_ID (Popup, Required) + info (DA like page 20) · P50_ADMISSION_ID (Select: patient's current admission, cascading; Display Null "OPD / Walk-in") |
| Tests | 8 | P50_TESTS **Shuttle** (height 12) · P50_CATEGORY (Select filter: `SELECT CATEGORY_NAME d, CATEGORY_ID r FROM HMS_SERVICE_CATEGORY WHERE CATEGORY_TYPE IN ('LAB','RADIOLOGY')`) — shuttle cascading parent P50_CATEGORY: `SELECT D,R FROM VW_LOV_SERVICE WHERE REPORTING_SECTION IS NOT NULL AND (:P50_CATEGORY IS NULL OR CATEGORY_ID=:P50_CATEGORY) ORDER BY D` |
| Order Info | 4 | P50_SOURCE (Radio `OPD,IPD,EMERGENCY,EXTERNAL`; default via DA: IPD if admission), P50_PRIORITY (pill ROUTINE/URGENT/STAT), P50_DOCTOR_ID (Popup VW_LOV_DOCTOR, "Referred by"), P50_NOTES (Textarea), P50_TOTAL (Display) |
DA **Total**: Change P50_TESTS → Server code (submit P50_TESTS, return P50_TOTAL):
```plsql
SELECT NVL(SUM(BASE_CHARGE),0) INTO :P50_TOTAL FROM HMS_SERVICE_MASTER
 WHERE SERVICE_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(APEX_STRING.SPLIT(:P50_TESTS,':')));
```
Button CREATE (`Place Order`, Hot, fa-flask) → Process:
```plsql
DECLARE l_no VARCHAR2(30);
BEGIN
  :P50_ORDER_ID := PKG_LAB.create_order(:G_BRANCH_ID, :P50_PATIENT_ID, :P50_SOURCE, NULL, :P50_ADMISSION_ID,
                                        :P50_DOCTOR_ID, :P50_PRIORITY, :P50_NOTES, l_no);
  PKG_LAB.add_tests(:P50_ORDER_ID, :P50_TESTS);
  :P50_ORDER_NO := l_no;
  IF :P50_ADMISSION_ID IS NULL THEN
     SELECT MAX(BILL_ID) INTO :P50_BILL_ID FROM HMS_BILLING WHERE BILL_TYPE='LAB' AND REMARKS=l_no;
  END IF;
END;
```
Validation: P50_TESTS not null. Branch: OPD → Page 71 (`P71_BILL_ID=&P50_BILL_ID.`) payment; IPD → Page 43.

---
## PAGE 51 — Sample Collection
Interactive Report 51, Static ID `samples`:
```sql
SELECT ORDER_DTL_ID, ORDER_NO, ORDER_DATE, PRIORITY, MRN, PATIENT_NAME, SERVICE_NAME,
       REPORTING_SECTION, PENDING_HOURS, NULL COLLECT
  FROM VW_LAB_PENDING
 WHERE BRANCH_ID = :G_BRANCH_ID AND ITEM_STATUS = 'ORDERED'
```
- PRIORITY STAT/URGENT → red/orange highlight · sort PRIORITY, ORDER_DATE
- Column COLLECT ▸ Type **Link** ▸ Link Text `<span class="t-Button t-Button--hot t-Button--small">Collect</span>` ▸ Target URL `javascript:collect(#ORDER_DTL_ID#);`
- Hidden item P51_DTL_ID · Page ▸ Function and Global Variable Declaration:
```javascript
function collect(id){
  apex.server.process('COLLECT',{x01:id},{success:function(d){
     apex.message.showPageSuccess('Sample no: '+d.sample_no);
     apex.region('samples').refresh();
     window.open(d.label_url,'_blank');   // label print
  }});
}
```
- Ajax Callback **COLLECT**:
```plsql
DECLARE l_no VARCHAR2(30);
BEGIN
  l_no := PKG_LAB.collect_sample(TO_NUMBER(APEX_APPLICATION.G_X01));
  APEX_JSON.open_object;
  APEX_JSON.write('sample_no', l_no);
  APEX_JSON.write('label_url', APEX_PAGE.GET_URL(p_page=>511, p_items=>'P511_SAMPLE_NO', p_values=>l_no));
  APEX_JSON.close_object;
END;
```
- **Page 511 Sample Label** (Minimal): Static text big `&P511_SAMPLE_NO.` + patient name + test + date; CSS `@page{size:50mm 25mm;margin:1mm}`, auto `window.print()`. (Barcode: `JsBarcode` library static file upload korle `<svg id="bc">` → `JsBarcode('#bc','&P511_SAMPLE_NO.')` — optional)
Authorization AUTH_LAB.

## PAGE 54 — Lab Worklist
Faceted Search 54 on `VW_LAB_PENDING WHERE BRANCH_ID=:G_BRANCH_ID` (sob pending status). Facets: REPORTING_SECTION, ITEM_STATUS, PRIORITY, ORDER_DATE. Results Classic/Cards: link → 52 `P52_DTL_ID=#ORDER_DTL_ID#`. PENDING_HOURS > TAT → red.

---
## PAGE 52 — Result Entry ⭐
Blank 52 ▸ P52_DTL_ID (checksum).
**Banner** Value pairs: `SELECT o.ORDER_NO, d.SERVICE_NAME, TRIM(p.FIRST_NAME||' '||p.LAST_NAME) patient, p.GENDER, FN_CALCULATE_AGE(p.DATE_OF_BIRTH) age, d.ITEM_STATUS FROM HMS_INVESTIGATION_ORDER_DTL d JOIN HMS_INVESTIGATION_ORDER o ON o.ORDER_ID=d.ORDER_ID JOIN HMS_PATIENT p ON p.PATIENT_ID=o.PATIENT_ID WHERE d.ORDER_DTL_ID=:P52_DTL_ID`
**Results IG** (Static ID `res_ig`):
```sql
SELECT ORDER_DTL_ID, PARAMETER_ID, GROUP_NAME, PARAMETER_NAME, RESULT_VALUE, UNIT,
       REFERENCE_RANGE, RESULT_FLAG, RESULT_STATUS, DISPLAY_ORDER
  FROM VW_LAB_RESULT_ENTRY WHERE ORDER_DTL_ID = :P52_DTL_ID
 ORDER BY DISPLAY_ORDER
```
| IG setting | Value |
|---|---|
| Attributes ▸ Edit | Enabled, Allowed Operations **Update Row** only |
| Primary Key | ORDER_DTL_ID + PARAMETER_ID (both columns ▸ Source ▸ Primary Key Yes) |
| Editable column | **RESULT_VALUE** only (baki gula Type Display Only) |
| RESULT_FLAG | Display Only, CSS: Column ▸ Appearance ▸ CSS Classes? → HTML Expression `<b class="flag-&RESULT_FLAG.">&RESULT_FLAG.</b>` |
| GROUP_NAME | Control Break (IG ▸ Actions ▸ Format ▸ Control Break, save default) |
| Toolbar | Save button ON, Add Row OFF |
Save process (auto created *Interactive Grid - Automatic Row Processing*) ▸ Target Type **PL/SQL Code**:
```plsql
PKG_LAB.save_result(:ORDER_DTL_ID, :PARAMETER_ID, :RESULT_VALUE);
```
Page CSS: `.flag-H,.flag-HH{color:#c62828}.flag-L,.flag-LL{color:#1565c0}.flag-HH,.flag-LL{background:#ffebee;padding:0 4px}`
Keyboard: IG te Enter = next row (built-in in edit mode).
Buttons:
| Button | Auth | Action |
|---|---|---|
| SAVE (IG toolbar) | AUTH_LAB | save → flags recompute; refresh IG after save (DA *Save [Interactive Grid]* event → Refresh) |
| VERIFY (Hot, fa-check-circle, confirm) | **AUTH_LAB_APPROVE** | Process `PKG_LAB.verify_test(:P52_DTL_ID);` → branch 54 |
| PREVIEW | – | → 53 new window |
Critical value (HH/LL) thakle: DA page load → `apex.message.alert('CRITICAL value ache! Doctor ke inform korun.')` (Condition: EXISTS HH/LL).

## PAGE 53 — Lab Report Print
Minimal template, P53_ORDER_ID (ba P53_DTL_ID). **Dynamic Content** region (PL/SQL Function Body returning a CLOB — Page 23 er moto `w()` + `RETURN l_html`):
- Header hospital + `LABORATORY REPORT`
- Patient block: name, age/sex, MRN, order no, ref. doctor, sample no, collection time, report time
- Per test (only VERIFIED): test name heading → table Parameter · Result · Unit · Reference Range, flag H/L bold red
- Footer: "Verified by" + employee name (VERIFIED_BY), pathologist signature line, "*** End of Report ***"
- Watermark `DRAFT` if not verified (CSS position fixed, opacity .1) — (shudhu verified print allow korle condition)
A4 CSS; PRINT button.

## Sprint 7 checklist
- [ ] Order (OPD) → LAB bill → payment · IPD order → IPD bill
- [ ] Collect → sample no + label
- [ ] Result → flag auto (range setup Sprint 3 e) → verify → report
- [ ] Dashboard Lab Pending card kome
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| PKG_LAB must be declared | `02_pkg_lab.sql` HMS_APP e run |
| Flag H/L ashe na | Reference range setup nai (Sprint 3) |
