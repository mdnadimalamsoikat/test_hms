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
| Banner | 12 | `Bill &P71_BILL_NO. · &P71_BILL_TYPE. · &P71_PNAME. (&P71_MRN.)` + status badge — template Hero ba Standard + hms-banner |
| Items | 8 | Classic Report (niche) |
| Summary | 4 | Static, CSS `hms-kpi blue`? — ba **Value Attribute Pairs** report |
| Add Item | 8 | Form items |
| Payment | 4 | Payment items |
| Receipts | 12 | Payment history |

**Items report** (Static ID `bill_items`):
```sql
SELECT BILL_DTL_ID, SERVICE_DATE, ITEM_DESC, REF_TYPE, QUANTITY, UNIT_PRICE, DISCOUNT_AMOUNT, NET_AMOUNT
  FROM HMS_BILLING_DTL WHERE BILL_ID = :P71_BILL_ID AND IS_ACTIVE = 'Y' ORDER BY BILL_DTL_ID
```
Sum on NET_AMOUNT. Delete icon column (Authorization AUTH_SUPER): link `javascript:` → DA confirm → server `UPDATE HMS_BILLING_DTL SET IS_ACTIVE='N' WHERE BILL_DTL_ID=:P71_DEL_ID; PKG_BILLING.recalc_bill(:P71_BILL_ID);` → refresh.

**Summary** region — Static Content, Text:
```html
<table class="hms-sum">
<tr><td>Gross</td><td>&P71_GROSS.</td></tr>
<tr><td>Discount</td><td>- &P71_DISC.</td></tr>
<tr><td><b>Net</b></td><td><b>&P71_NET.</b></td></tr>
<tr><td>Paid</td><td>&P71_PAID.</td></tr>
<tr class="due"><td>DUE</td><td>&P71_DUE.</td></tr></table>
```
Page inline CSS: `.hms-sum{width:100%;font-size:1.1rem}.hms-sum td:last-child{text-align:right}.hms-sum .due td{font-size:1.6rem;color:#c62828;font-weight:700;border-top:2px solid #333}`

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
Blank 72. Items: P72_PATIENT_ID (Popup, Required), P72_FROM (Date, default -30d), P72_TO (Date, default today), button GO.
Classic Report (Page Items to Submit all 3):
```sql
SELECT dt, doc_no, particulars, debit, credit,
       SUM(debit - credit) OVER (ORDER BY dt, doc_no ROWS UNBOUNDED PRECEDING) balance
FROM (
  SELECT BILL_DATE dt, BILL_NO doc_no, BILL_TYPE||' Bill' particulars, NET_AMOUNT debit, 0 credit
    FROM HMS_BILLING WHERE PATIENT_ID=:P72_PATIENT_ID AND BILL_STATUS<>'CANCELLED'
  UNION ALL
  SELECT RECEIPT_DATE, RECEIPT_NO, RECEIPT_TYPE||' - '||PAYMENT_MODE,
         CASE WHEN RECEIPT_TYPE='REFUND' THEN AMOUNT ELSE 0 END,
         CASE WHEN RECEIPT_TYPE<>'REFUND' THEN AMOUNT ELSE 0 END
    FROM HMS_PAYMENT_RECEIPT WHERE PATIENT_ID=:P72_PATIENT_ID AND RECEIPT_STATUS='VALID' AND RECEIPT_TYPE<>'ADJUSTMENT')
WHERE dt BETWEEN TO_DATE(:P72_FROM,'DD-MON-YYYY') AND TO_DATE(:P72_TO,'DD-MON-YYYY') + 1
ORDER BY dt, doc_no
```
Sum debit/credit. PRINT button (window.print). Authorization AUTH_BILLING.

---
## PAGE 73 — Invoice / Money Receipt Print
Blank 73 ▸ Page Template **Minimal (No Navigation)**. Items P73_BILL_ID, P73_RECEIPT_ID (checksum).
**Dynamic Content** region (PL/SQL Function Body returning a CLOB — Page 23 er moto `w()` + `RETURN l_html`) (same technique as page 23):
- Header: branch name/address/phone (HMS_BRANCH)
- Title: `INVOICE` (ba `MONEY RECEIPT` jodi P73_RECEIPT_ID)
- Bill no, date, patient, MRN, bill type, (OPD hole Token No bold — `SELECT TOKEN_NO FROM HMS_OPD_VISIT WHERE VISIT_ID = bill.OPD_VISIT_ID`)
- Table: SL · Description · Qty · Rate · Disc · Amount (HMS_BILLING_DTL)
- Totals: Gross, Discount, Net, Paid, Due
- In words: `INITCAP(TO_CHAR(TO_DATE(TRUNC(amt),'J'),'JSP')) || ' Taka Only'`
- Receipt block (if receipt): receipt no, mode, TXN, amount
- Footer: cashier `&G_FULL_NAME.`, print time
CSS: `@page{size:A5;margin:8mm}` · font 12px · table border-collapse.
Buttons PRINT (window.print, Hot) · BACK (`javascript:history.back()`).
Auto print: DA Page Load → `window.print();` (optional).

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
