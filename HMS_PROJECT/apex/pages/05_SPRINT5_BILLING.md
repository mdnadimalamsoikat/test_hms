# SPRINT 5 — Billing & Cash (Page 70, 701, 71, 72, 73)

🎯 **Ei sprint e ki hobe:** Bill dekha, item add, discount, payment, invoice print. Sob hisab PKG_BILLING kore.

## Shuru-r age (check)
- [ ] Sprint 4 (OPD visit theke bill toiri hoy — test bill paben)
- [ ] AUTH_BILLING, _ADD, _APPROVE, AUTH_SUPER

**Build order:** 70 list → 71 bill → 701 misc bill → 72 statement → 73 print

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Rule: **Bill er amount kokhono APEX e calculate/update korben na** — shob PKG_BILLING (recalc, discount, payment, cancel).

---
## PAGE 70 — Bills (list)
Create Page ▸ **Faceted Search** 70 `Bills`:
```sql
SELECT BILL_ID, BILL_NO, BILL_DATE, BILL_TYPE, MRN, PATIENT_NAME, PHONE_PRIMARY,
       NET_AMOUNT, PAID_AMOUNT, DUE_AMOUNT, BILL_STATUS
  FROM VW_BILL_LIST WHERE BRANCH_ID = :G_BRANCH_ID
```
Facets: P70_SEARCH (BILL_NO, MRN, PATIENT_NAME, PHONE_PRIMARY) · BILL_TYPE (checkbox) · BILL_STATUS (checkbox) · BILL_DATE (Date Range, default today) · Due only (checkbox on `CASE WHEN DUE_AMOUNT>0 THEN 'Y' END` column).
Results → **Classic Report** (table view better for money):
- Amount columns ▸ Format `FML999G999G990D00`, Alignment Right, Heading `(Tk)`
- DUE_AMOUNT ▸ HTML Expression `<b style="color:#c62828">#DUE_AMOUNT#</b>` (Condition? all fine)
- BILL_STATUS badge · BILL_NO ▸ Link → 71 `P71_BILL_ID=#BILL_ID#`
- Enable **Sum** on NET/PAID/DUE: Classic Report ▸ column ▸ *Compute Sum* ON
Buttons: `New Misc Bill` → 701 (Hot) · `Export` (IR na, tai CSV: Attributes ▸ Download ON).
Authorization **AUTH_BILLING**.

## PAGE 701 — Create Bill (Modal, 520)
Items: P701_PATIENT_ID (Popup VW_LOV_PATIENT, Required) · P701_BILL_TYPE (Select Static: `MISC,LAB,OT,PACKAGE,EMERGENCY`) · P701_ADMISSION_ID (optional select of patient's current admission, cascading).
Process CREATE:
```plsql
:P701_BILL_ID := PKG_BILLING.create_bill(:G_BRANCH_ID, :P701_PATIENT_ID, :P701_BILL_TYPE, NULL, :P701_ADMISSION_ID);
```
Then **Close Dialog** ▸ Items to Return `P701_BILL_ID`. Page 70 ▸ DA *Dialog Closed* → Redirect JS: `apex.navigation.redirect(apex.util.makeApplicationUrl({pageId:71, itemNames:['P71_BILL_ID'], itemValues:[this.data.P701_BILL_ID]}))` — ba simple: 701 er Branch → Page 71 (modal theke normal page e redirect er jonno Close Dialog er bodole Branch *Redirect to Page* use korle APEX nijei parent reload kore).

---
## PAGE 71 — Bill Detail & Cashier ⭐
Create Page ▸ Blank 71 `Bill` ▸ Authorization AUTH_BILLING ▸ Page Access Protection checksum.
Hidden: P71_BILL_ID (checksum), P71_PATIENT_ID, P71_STATUS.

### Pre-Rendering: Load
```plsql
SELECT BILL_NO, BILL_TYPE, BILL_DATE, PATIENT_ID, MRN, PATIENT_NAME, GROSS_AMOUNT, DISCOUNT_AMOUNT,
       NET_AMOUNT, PAID_AMOUNT, DUE_AMOUNT, BILL_STATUS
  INTO :P71_BILL_NO, :P71_BILL_TYPE, :P71_BILL_DATE, :P71_PATIENT_ID, :P71_MRN, :P71_PNAME, :P71_GROSS, :P71_DISC,
       :P71_NET, :P71_PAID, :P71_DUE, :P71_STATUS
  FROM VW_BILL_LIST WHERE BILL_ID = :P71_BILL_ID;
```
(sob P71_* hidden/display items)

### Layout
| Region | Span | Content |
|---|---|---|
| Banner | 12 | Existing bill/patient/date fields + status badge; Standard region, CSS Classes `hms-bill-banner` |
| Summary | 12 | Static Content with five KPI cards; region CSS Classes `hms-bill-summary` |
| Items | 12 | Classic Report; region CSS Classes `hms-wide`; Layout → Column Span `12` |
| Add Item | 8 | Form items |
| Payment | 4 | Payment items |
| Receipts | 12 | Payment history |

**Items report** (Static ID `bill_items`):
```sql
SELECT BILL_DTL_ID, SERVICE_DATE, ITEM_DESC, REF_TYPE, QUANTITY, UNIT_PRICE, DISCOUNT_AMOUNT, NET_AMOUNT
  FROM HMS_BILLING_DTL WHERE BILL_ID = :P71_BILL_ID AND IS_ACTIVE = 'Y' ORDER BY BILL_DTL_ID
```
Page Designer → Rendering tree → **Bill Items** Classic Report region select → Property Editor → **Appearance → CSS Classes** = `hms-wide` (no dot; keep Static ID `bill_items` unchanged). Layout → **Column Span = 12**. `hms-wide` widens the Classic Report table inside its region; Column Span makes the region itself use the full page row. Just adding the CSS class cannot expand a region still set to Span 8.

Sum on NET_AMOUNT. Delete icon column (Authorization AUTH_SUPER): link `javascript:` → DA confirm → server `UPDATE HMS_BILLING_DTL SET IS_ACTIVE='N' WHERE BILL_DTL_ID=:P71_DEL_ID; PKG_BILLING.recalc_bill(:P71_BILL_ID);` → refresh.

**Summary** region — Static Content, full-width. Page Designer → Rendering tree → click `Summary` region → Property Editor → Appearance → **CSS Classes** = `hms-bill-summary` (class name only; no leading dot). Keep the database-loaded `P71_GROSS`, `P71_DISC`, `P71_NET`, `P71_PAID`, `P71_DUE` values; this is display-only and must not calculate or update bill amounts. Replace the old summary table with:
```
<div class="hms-kpi-row">
  <div class="hms-kpi blue"><span class="hms-kpi-lbl">Gross</span><span class="hms-kpi-val">Tk&nbsp;&P71_GROSS.</span></div>
  <div class="hms-kpi orange"><span class="hms-kpi-lbl">Discount</span><span class="hms-kpi-val">Tk&nbsp;&P71_DISC.</span></div>
  <div class="hms-kpi purple"><span class="hms-kpi-lbl">Net</span><span class="hms-kpi-val">Tk&nbsp;&P71_NET.</span></div>
  <div class="hms-kpi green"><span class="hms-kpi-lbl">Paid</span><span class="hms-kpi-val">Tk&nbsp;&P71_PAID.</span></div>
  <div class="hms-kpi red"><span class="hms-kpi-lbl">Due</span><span class="hms-kpi-val">Tk&nbsp;&P71_DUE.</span></div>
</div>
```
The currency and existing formatted amount stay together on one line (`&nbsp;`); do not insert `<br>` between them. The shared CSS turns the old large solid blocks into five compact, label-aligned cards and collapses to three/two columns on narrow screens. Banner region → Appearance → CSS Classes = `hms-bill-banner`; its final status badge is styled as a single badge instead of a nested chip.

**Add Item** (Condition `:P71_STATUS IN ('OPEN','PARTIAL')`, Authorization AUTH_BILLING_ADD):
P71_SERVICE_ID (Popup VW_LOV_SERVICE, Span 6) · P71_QTY (Number default 1, Span 2) · P71_ITEM_DISC (Number default 0, Span 2) · Button ADD_ITEM (Span 2, fa-plus)
Process ADD_ITEM: `PKG_BILLING.add_bill_item(:P71_BILL_ID, :P71_SERVICE_ID, NULL, :P71_QTY, NULL, NVL(:P71_ITEM_DISC,0));` → Branch same page (clears inputs: Clear Cache item list).

**Discount** (sub-region, Authorization **AUTH_BILLING_APPROVE**): P71_HDR_DISC (Number), P71_DISC_REASON (Text, required) · Button APPLY_DISCOUNT (confirm) →
`PKG_BILLING.apply_discount(:P71_BILL_ID, :P71_HDR_DISC, :P71_DISC_REASON, :G_EMPLOYEE_ID);`

**Payment** (Condition DUE > 0):
| Item | Type |
|---|---|
| P71_PAY_AMOUNT | Number, Default `&P71_DUE.` (PL/SQL `:P71_DUE`), Required, Max validation ≤ DUE |
| P71_PAY_MODE | Radio pill, LOOKUP 'PAYMENT_MODE' |
| P71_TXN_REF | Text (Show if mode ≠ CASH) — bKash/Nagad TrxID, card last4 |
| Button RECEIVE (Hot, fa-money, label `Receive Payment`) | |
Process RECEIVE:
```plsql
:P71_RECEIPT_ID := PKG_BILLING.receive_payment(:P71_BILL_ID, :P71_PAY_AMOUNT, :P71_PAY_MODE, :P71_TXN_REF, :G_EMPLOYEE_ID);
```
Branch → Page 73 (`P73_RECEIPT_ID=&P71_RECEIPT_ID.`, `P73_BILL_ID`).
Validation: `:P71_PAY_AMOUNT > 0 AND :P71_PAY_AMOUNT <= :P71_DUE` · TXN_REF required if mode not CASH.
IPD bill hole button `ADJUST_ADVANCE` → `PKG_BILLING.adjust_advance(:P71_BILL_ID);`

**Receipts** (Classic): `SELECT RECEIPT_NO, RECEIPT_DATE, RECEIPT_TYPE, PAYMENT_MODE, AMOUNT, TRANSACTION_REF, RECEIPT_STATUS, RECEIPT_ID FROM HMS_PAYMENT_RECEIPT WHERE BILL_ID=:P71_BILL_ID ORDER BY RECEIPT_DATE` · RECEIPT_NO link → 73 reprint.

**Footer buttons:** PRINT_INVOICE (→73 `P73_BILL_ID`) · CANCEL_BILL (Danger, AUTH_SUPER, Condition PAID=0; modal reason item P71_CANCEL_REASON → `PKG_BILLING.cancel_bill(:P71_BILL_ID, :P71_CANCEL_REASON);`) · BACK (→70).

**Error handling:** protiti process ▸ Error ▸ Display Location *Inline in Notification* — package er `-201xx` message user dekhbe.

✅ Test: add 2 service → total thik · discount (approve role) · partial payment → status PARTIAL · full → PAID · cancel.

---
## PAGE 72 — Patient Account Statement
**Kaj:** Ekjon patient-er nirdishto tarikh-er bill charge, payment, refund, advance adjustment ebong running balance dekha. Bill amount `PKG_BILLING` theke ashe; ei report kono bill update kore na.

Blank Page 72 `Patient Account Statement` korun. Page Security: Authorization Scheme `AUTH_BILLING`; Page Access Protection `Arguments Must Have Checksum`.

Items:
- `P72_PATIENT_ID` — Popup LOV; LOV query `SELECT D, R FROM VW_LOV_PATIENT WHERE BRANCH_ID=:G_BRANCH_ID ORDER BY D`. `VW_LOV_PATIENT` active patient dey; branch condition chara rakhben na.
- `P72_FROM` — Date Picker, Format Mask `DD-MM-YYYY`.
- `P72_TO` — Date Picker, Format Mask `DD-MM-YYYY`.

APEX date field-e `12-11-2026` er moto value dekhale mask `DD-MM-YYYY`. Ei item duitar Format Mask, default process, validation ebong report query-te **ekoi `DD-MM-YYYY`** use korte hobe; `DD-MON-YYYY` dile ORA-01843 hobe.

Before Header process `SET_DEFAULT_DATES` (PL/SQL Code):
```
BEGIN
  IF :P72_FROM IS NULL THEN
    :P72_FROM := TO_CHAR(TRUNC(SYSDATE) - 29, 'DD-MM-YYYY');
  END IF;

  IF :P72_TO IS NULL THEN
    :P72_TO := TO_CHAR(TRUNC(SYSDATE), 'DD-MM-YYYY');
  END IF;
END;
```
`GO` button page submit korbe. Required validation `P72_PATIENT_ID`, `P72_FROM`, `P72_TO`-te din; date-range validation `GO` button-e chalaben:
```
BEGIN
  RETURN TO_DATE(:P72_FROM, 'DD-MM-YYYY')
      <= TO_DATE(:P72_TO, 'DD-MM-YYYY');
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
```
Error Message: `From date must be on or before To date.` · Associated Item: `P72_TO` · Display Location: `Inline with Field and in Notification` · Server-side Condition: When Button Pressed `GO`.

Classic Report `Account Statement` (GO full page submit kore, tai `Page Items to Submit` lagbe na). Query:
```
WITH all_tx AS (
  SELECT b.BILL_DATE AS dt,
         b.BILL_NO AS doc_no,
         b.BILL_TYPE || ' Bill' AS particulars,
         NVL(b.PATIENT_PAYABLE, 0) AS debit,
         0 AS credit,
         1 AS sort_group,
         b.BILL_ID AS sort_id
    FROM HMS_BILLING b
   WHERE b.PATIENT_ID = :P72_PATIENT_ID
     AND b.BRANCH_ID = :G_BRANCH_ID
     AND b.IS_ACTIVE = 'Y'
     AND b.BILL_STATUS NOT IN ('DRAFT', 'CANCELLED')

  UNION ALL

  SELECT r.RECEIPT_DATE,
         r.RECEIPT_NO,
         r.RECEIPT_TYPE || ' - ' || NVL(r.PAYMENT_MODE, ''),
         CASE WHEN r.RECEIPT_TYPE = 'REFUND' THEN r.AMOUNT ELSE 0 END,
         CASE WHEN r.RECEIPT_TYPE = 'REFUND' THEN 0 ELSE r.AMOUNT END,
         2,
         r.RECEIPT_ID
    FROM HMS_PAYMENT_RECEIPT r
    JOIN HMS_BILLING b
      ON b.BILL_ID = r.BILL_ID
     AND b.PATIENT_ID = :P72_PATIENT_ID
     AND b.BRANCH_ID = :G_BRANCH_ID
     AND b.IS_ACTIVE = 'Y'
     AND b.BILL_STATUS NOT IN ('DRAFT', 'CANCELLED')
   WHERE r.PATIENT_ID = :P72_PATIENT_ID
     AND r.BRANCH_ID = :G_BRANCH_ID
     AND r.BILL_ID IS NOT NULL
     AND r.RECEIPT_STATUS = 'VALID'
     AND r.IS_ACTIVE = 'Y'
),
opening AS (
  SELECT NVL(SUM(debit - credit), 0) AS opening_balance
    FROM all_tx
   WHERE dt < TO_DATE(:P72_FROM, 'DD-MM-YYYY')
),
period_tx AS (
  SELECT dt, doc_no, particulars, debit, credit, sort_group, sort_id
    FROM all_tx
   WHERE dt >= TO_DATE(:P72_FROM, 'DD-MM-YYYY')
     AND dt <  TO_DATE(:P72_TO, 'DD-MM-YYYY') + 1
),
statement_rows AS (
  SELECT CAST(TO_DATE(:P72_FROM, 'DD-MM-YYYY') AS TIMESTAMP) AS dt,
         'OPENING' AS doc_no,
         'Opening Balance' AS particulars,
         CASE WHEN opening_balance > 0 THEN opening_balance ELSE 0 END AS debit,
         CASE WHEN opening_balance < 0 THEN ABS(opening_balance) ELSE 0 END AS credit,
         0 AS sort_group,
         0 AS sort_id
    FROM opening

  UNION ALL

  SELECT dt, doc_no, particulars, debit, credit, sort_group, sort_id
    FROM period_tx
)
SELECT dt,
       doc_no,
       particulars,
       debit,
       credit,
       SUM(debit - credit) OVER (
         ORDER BY dt, sort_group, sort_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS balance,
       sort_group,
       sort_id
  FROM statement_rows
 ORDER BY dt, sort_group, sort_id
```
`PATIENT_PAYABLE` use korchi, `NET_AMOUNT` noy—insurance thakle patient-er nijer baki taka-i dekhabey. `ADJUSTMENT` credit-e dhora hoy; `REFUND` debit-e dhora hoy. `SORT_GROUP` o `SORT_ID` report column duita hide korun; `BALANCE`-e running total dekhabe. Opening Balance tarikh range-er ager transaction theke ashe.

Column heading: `DT` = `Date`; `DOC_NO` = `Document #`; `PARTICULARS` = `Details`; `DEBIT` = `Charge (Tk)`; `CREDIT` = `Received (Tk)`; `BALANCE` = `Balance (Tk)`. `DT` Format Mask `DD-MON-YYYY HH24:MI`; money column-gulor Format Mask `FM999G999G999G990D00`. `Compute Sum` On korben na. When No Data Found English message: `No account transactions were found for this patient and date range.`

`PRINT_STATEMENT` button → Dynamic Action (Click, Button `PRINT_STATEMENT`) → True Action `Execute JavaScript Code` → `window.print();`. Application authorization `AUTH_BILLING`. Unadjusted patient advance ei bill statement-e thakbe na; advance bill-e adjust hole `ADJUSTMENT` receipt hisebe dekhabe.

---
## PAGE 73 — Invoice / Money Receipt Print
Blank Page 73 `Invoice / Money Receipt` ▸ Page Template **Minimal (No Navigation)** ▸ Security → Authorization Scheme `AUTH_BILLING` ▸ Page Access Protection `Arguments Must Have Checksum`.

### 1. Fix the visible `New` / `341` boxes from the screenshot
Page Designer → Rendering tree search box-e `P73_BILL_ID` likhe item select korun → Property Editor → **Identification** → **Type = Hidden**. Abar `P73_RECEIPT_ID` search/select kore same Type `Hidden` korun. Prottek item-er **Security → Value Protected = On** rakhun. `P73_BILL_ID` invoice/reprint-er bill ID; `P73_RECEIPT_ID` optional receipt ID—duita item thakbe, kintu page-e form field hisebe render hobe na.

Page runtime-e jodi `New` / number-er dashed field ekhono thake, Page Designer Rendering tree-te visible field-er upor click kore tar **actual item name** ber korun. Screenshot-er control `P73_BILL_ID` ba `P73_RECEIPT_ID` na hole oi control-i identify kore hide/remove korun; item name dekha chara andaj kore hidden ache dhore neben na. Invoice content region ba patient/bill details hide korben na.

### 2. Existing invoice content region-er CSS class
Invoice-er current **Dynamic Content** region select korun (notun duplicate invoice region banaben na) → Property Editor → **Appearance → CSS Classes** = `hms-invoice`. CSS class-er age `.` diben na.
- Bill items alada Classic Report region hole, oi report region-er CSS Classes = `hms-invoice-items`. Bill-item HTML table Dynamic Content region-er bhitore thakle alada class lagbe; `hms-invoice`-er nested table style avabei pabe.
- KPI/summary card-gulo alada region-e thakle oi region-er CSS Classes = `hms-invoice-summary`; same Dynamic Content region-er moddhe thakle existing `.hms-kpi-row`/`.hms-kpi` markup rakhun.
- `Document Actions` (Print/Back) region select korun → Appearance → CSS Classes = `hms-invoice-actions`. Print CSS-e puro actions region lukabe, tai printed invoice-e region title ba khali card thakbe na.

### 3. Invoice-er data o readable markup
Existing Dynamic Content region-er PL/SQL Function Body returning a CLOB (Page 23-r `w()` + `RETURN l_html` pattern) rakhun. Eta **display-only**: `HMS_BILLING`, `HMS_BILLING_DTL`, receipt/branch/patient/OPD visit theke current value porbe; bill, payment ba total calculate/update korbe na.
- Header: `HMS_BRANCH` theke branch name, address, phone.
- Title: receipt ID thakle `MONEY RECEIPT`, na thakle `INVOICE`.
- Bill no/date, patient, MRN, bill type; OPD hole bold Token No (`HMS_OPD_VISIT.TOKEN_NO` via bill-er `OPD_VISIT_ID`).
- Line items: `#`, `Description`, `Qty`, `Rate (Tk)`, `Discount (Tk)`, `VAT (Tk)`, `Net (Tk)`; headings Title Case-e rakhun. APEX Classic Report use korle Page Items to Submit `P73_BILL_ID` din ebong query-te existing `HMS_BILLING_DTL` values-i select korun.
- Gross, Discount, Net, Paid, Due—bill record-er existing values. Receipt thakle receipt no, mode, transaction reference, amount receipt row theke show korun.
- Amount-in-words existing formatter diye asbe; cashier `&G_FULL_NAME.` ebong print time footer-e rakhun.

Raw database text CLOB HTML-e jorle `APEX_ESCAPE.HTML` diye escape korun; HTML attribute-e value dile `APEX_ESCAPE.HTML_ATTRIBUTE` use korun. Amount-er display string-o existing number/format value theke nin. Prottek total-er markup-e currency o existing formatted amount **ekoi `.hms-kpi-val` element-e** rakhun—example shape `<span class="hms-kpi-val">Tk&nbsp;1,000.00</span>`; real page-e `1,000.00`-er jaygay current database-derived formatted value bosbe. `Tk`-r pore `<br>` ba alada block diben na. Eta wrapping fix kore; kono amount math kore na.

### 4. Print, Back, CSS, and test
Page 73 page node select kore Property Editor-er search-e `Inline` khujun → **CSS → Inline**-e ei page-specific print paper rule din (shared `hms.css`-e diben na; onnanno page-er print size change hobe na):
```
@page { size: A5 landscape; margin: 8mm; }
@media print {
  .t-Body-title, #apexDevToolbar, .a-DevToolbar { display: none !important; }
}
```
Ei page-specific rule APEX page title/developer toolbar sudhu Page 73-r print-e hide korbe; shared CSS-er maddhome onno page-er print title change hobe na. Shared `hms.css` + `hms.min.css`-e Page 71/73-r card, invoice table, print-only CSS ache. `Shared Components → Static Application Files`-e repo-r **dui file-i** replace korun. CSS URL `#APP_FILES#static/hms#MIN#.css` hole same path rakhun; update-er por Page 71/73 run kore **Ctrl+F5** din.

- PRINT button: existing button-e Click Dynamic Action → True Action **Execute JavaScript Code** → `window.print();`. Page Load-e auto-print DA rakhben na—cashier age invoice verify kore tarpor print button chapbe.
- BACK button: `javascript:history.back()` noy. APEX Link Builder → Page in this Application `71` → Set Items `P71_BILL_ID` = `&P73_BILL_ID.` → Clear Cache `71`. Link Builder-ke URL/checksum generate korte din.
- Print preview test: Page 71 theke Page 73 khulun; screen-e `New`/`341` control na thaka, 5 total card-e `Tk 1,000.00` eki line-e thaka, ebong item table-e Description/Qty/Rate/Discount/VAT/Net alada pora jacche kina dekhen. PRINT chaple preview-te shudhu invoice/receipt thakbe—Page title, Document Actions, Back/Print button, navigation/footer/Developer Toolbar na thaka verify korun. Bill/receipt data unchanged thaka confirm korun; invoice/receipt amount kono page process-e update hobe na.

## Sprint 5 checklist
- [ ] OPD visit (Sprint 4) → bill page 71 e dekhay
- [ ] Misc bill + items + discount + payment + print
- [ ] Statement balance thik
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Amount vul | APEX e amount column edit korben na — PKG_BILLING.recalc_bill |
| Payment e ORA-201xx | Due er beshi payment / bill cancelled |
