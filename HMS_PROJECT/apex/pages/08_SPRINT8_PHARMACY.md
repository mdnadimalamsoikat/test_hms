# SPRINT 8 — Pharmacy (Page 60, 61, 62, 63, 64, 65)

🎯 **Ei sprint e ki hobe:** GRN diye stock → POS sale → PO, stock/expiry report, return.

## Shuru-r age (check)
- [ ] DB: `04_pharmacy_cart.sql` run (POS cart remove)
- [ ] Sprint 3: Store, Supplier, Medicine master

**Build order:** 62 GRN age (stock chara sale hoy na) → 60 POS → 61 PO → 66 → 63 → 64 → 65

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Order: **62 GRN age** (stock na thakle sale hobe na) → 60 POS → 61 PO → 63/64 → 65.
Package: `PKG_PHARMACY` (FEFO batch auto, stock trigger).

---
## PAGE 61 — Purchase Order (Master-Detail)
Create Page ▸ **Master Detail** ▸ **Drill Down** style ▸ Master `HMS_PHARMA_PURCHASE_ORDER` (61 list, 611 form) ▸ Detail `HMS_PHARMA_PO_DTL` (IG inside 611).
611 master form: PO_NO (Display; Before-insert process `:P611_PO_NO := FN_GET_NEXT_NO(:G_BRANCH_ID,'PO')`), BRANCH_ID (hidden default), SUPPLIER_ID (Popup `SELECT SUPPLIER_NAME d, SUPPLIER_ID r FROM HMS_PHARMA_SUPPLIER WHERE IS_ACTIVE='Y'`), PO_DATE (default today), EXPECTED_DATE, PO_STATUS (Display; default DRAFT), REMARKS.
Detail IG: ITEM_ID (Popup VW_LOV_MEDICINE), ORDER_QTY, UNIT_PRICE (default via column DA: `SELECT PURCHASE_PRICE FROM HMS_PHARMA_ITEM WHERE ITEM_ID=:ITEM_ID`), LINE_TOTAL (Display; IG column *Default* none; compute in IG save or via trigger — JS DA: `:ORDER_QTY * :UNIT_PRICE`), RECEIVED_QTY (Display).
After save process: `UPDATE HMS_PHARMA_PURCHASE_ORDER SET TOTAL_AMOUNT=(SELECT SUM(ORDER_QTY*UNIT_PRICE) FROM HMS_PHARMA_PO_DTL WHERE PO_ID=:P611_PO_ID) WHERE PO_ID=:P611_PO_ID;`
Button APPROVE (Security ▸ Authorization **AUTH_SUPER**): `UPDATE ... SET PO_STATUS='APPROVED', APPROVED_BY=:G_EMPLOYEE_ID WHERE PO_ID=:P611_PO_ID AND PO_STATUS='DRAFT';`
Edit lock: Condition item/IG read-only when `:P611_PO_STATUS <> 'DRAFT'` (Region ▸ Read Only ▸ Item != DRAFT).
Print PO (Minimal page 612) optional.

## PAGE 62 — GRN (Goods Receipt) ⭐
Master Detail Drill Down: master `HMS_PHARMA_GRN` (62 list, 621 form), detail `HMS_PHARMA_GRN_DTL` IG.
621 form: GRN_NO (auto `FN_GET_NEXT_NO(:G_BRANCH_ID,'GRN')`), PO_ID (Select approved/partial POs of supplier, optional), SUPPLIER_ID, STORE_ID (Select `SELECT STORE_NAME d, STORE_ID r FROM HMS_PHARMA_STORE WHERE BRANCH_ID=:G_BRANCH_ID`), GRN_DATE, INVOICE_NO (Required), INVOICE_DATE, DISCOUNT_AMOUNT, VAT_AMOUNT, TOTAL/NET (Display), GRN_STATUS (Display DRAFT).
Detail IG columns: ITEM_ID (popup), **BATCH_NO** (Required), MFG_DATE, **EXPIRY_DATE** (Required, validation > SYSDATE), QUANTITY, FREE_QTY, UNIT_COST, MRP (default item MRP), LINE_TOTAL (display).
Button **Load from PO** (when PO selected, DRAFT): server code
```plsql
INSERT INTO HMS_PHARMA_GRN_DTL (GRN_ID, ITEM_ID, QUANTITY, UNIT_COST, MRP, BATCH_NO, EXPIRY_DATE)
SELECT :P621_GRN_ID, d.ITEM_ID, d.ORDER_QTY - NVL(d.RECEIVED_QTY,0), d.UNIT_PRICE, i.MRP, 'TBD', ADD_MONTHS(TRUNC(SYSDATE),24)
  FROM HMS_PHARMA_PO_DTL d JOIN HMS_PHARMA_ITEM i ON i.ITEM_ID=d.ITEM_ID
 WHERE d.PO_ID=:P621_PO_ID AND d.ORDER_QTY > NVL(d.RECEIVED_QTY,0);
```
(then user batch/expiry edit kore)
Button **POST** (Hot, confirm "Post korle stock e jog hobe, ar edit kora jabe na"):
`PKG_PHARMACY.post_grn(:P621_GRN_ID);` → status POSTED, stock in, PO received qty update.
Read-only when POSTED. Authorization AUTH_PHARMACY_ADD.

---
## PAGE 60 — Pharmacy POS (Sale) ⭐⭐
Blank 60 `Pharmacy Sale` ▸ Authorization AUTH_PHARMACY_ADD ▸ Page ▸ Appearance ▸ CSS Classes? none.
Hidden: P60_SALE_ID, P60_STORE_ID (default: `SELECT MIN(STORE_ID) FROM HMS_PHARMA_STORE WHERE BRANCH_ID=:G_BRANCH_ID AND STORE_TYPE IN ('MAIN','OPD')`).

### Layout
```
┌ Customer (12): [OTC|OPD|IPD] Patient ▾  Name  Phone  Prescription ▾ ─────────┐
├ Scan / Search (8) ──────────────────────────┬ Summary (4, sticky) ────────────┤
│ [Medicine ▾ search/barcode] [Qty] [Disc] [+] │ Gross      1,250.00             │
│ ── Cart (classic report) ──                  │ Discount     -50.00             │
│ Napa 500 | B123 | 12/27 | 10 | 2.50 | 25 🗑   │ NET        1,200.00 (big)       │
│ ...                                          │ Paid [____] Mode (Cash|bKash..) │
│                                              │ Change       300.00             │
│                                              │ [ Complete Sale ] [ Cancel ]    │
└──────────────────────────────────────────────┴─────────────────────────────────┘
```
### Items
| Item | Type | Setting |
|---|---|---|
| P60_SALE_TYPE | Radio pill | `OTC;OTC,OPD;OPD,IPD;IPD,Emergency;EMERGENCY` default OTC |
| P60_PATIENT_ID | Popup | VW_LOV_PATIENT · Show when type ≠ OTC |
| P60_ADMISSION_ID | Select cascading on patient | current admission · Show when IPD |
| P60_PRESCRIPTION_ID | Select | `SELECT rx.PRESCRIPTION_NO||' - '||TO_CHAR(rx.PRESCRIPTION_DATE,'DD-Mon') d, rx.PRESCRIPTION_ID r FROM HMS_OPD_PRESCRIPTION rx JOIN HMS_OPD_VISIT v ON v.VISIT_ID=rx.VISIT_ID WHERE v.PATIENT_ID=:P60_PATIENT_ID ORDER BY rx.PRESCRIPTION_DATE DESC` · Button `Load Rx` |
| P60_CUSTOMER / P60_PHONE | Text | OTC |
| P60_ITEM_ID | Popup LOV | VW_LOV_MEDICINE · Settings ▸ **Search as You Type**, Display As *Inline Popup*, min chars 2 · barcode: LOV SQL e `BARCODE` column add + search column list |
| P60_QTY | Number | default 1 |
| P60_ITEM_DISC | Number | default 0 |
| P60_GROSS/P60_DISC/P60_NET | Display | Summary |
| P60_PAID | Number | Default NET (DA) |
| P60_PAY_MODE | Radio pill | LOOKUP PAYMENT_MODE |
| P60_CHANGE | Display | JS `paid-net` |

### Cart region (Classic Report, Static ID `cart`, Page Items to Submit P60_SALE_ID)
```sql
SELECT d.SALE_DTL_ID, i.ITEM_NAME||' '||i.STRENGTH item, d.BATCH_NO, TO_CHAR(s.EXPIRY_DATE,'MM/YY') exp,
       d.QUANTITY, d.UNIT_PRICE, d.DISCOUNT_AMOUNT, d.LINE_TOTAL, NULL del
  FROM HMS_PHARMA_SALE_DTL d
  JOIN HMS_PHARMA_ITEM i ON i.ITEM_ID=d.ITEM_ID
  LEFT JOIN HMS_PHARMA_STOCK s ON s.STOCK_ID=d.STOCK_ID
 WHERE d.SALE_ID = :P60_SALE_ID AND d.IS_ACTIVE='Y'
 ORDER BY d.SALE_DTL_ID
```
DEL column link `javascript:removeLine(#SALE_DTL_ID#)` icon `fa-trash-o`. No data: `Cart khali — medicine scan/search korun`.

### Add item — Ajax (no page submit, fast)
Button ADD (fa-plus, Hot) → DA Click → **Execute Server-side Code** (Items to Submit: P60_SALE_ID, P60_STORE_ID, P60_SALE_TYPE, P60_PATIENT_ID, P60_ADMISSION_ID, P60_CUSTOMER, P60_PHONE, P60_ITEM_ID, P60_QTY, P60_ITEM_DISC · Items to Return: P60_SALE_ID, P60_GROSS, P60_DISC, P60_NET):
```plsql
BEGIN
  IF :P60_SALE_ID IS NULL THEN
     :P60_SALE_ID := PKG_PHARMACY.create_sale(:G_BRANCH_ID, :P60_STORE_ID, :P60_SALE_TYPE, :P60_PATIENT_ID,
                                              :P60_ADMISSION_ID, :P60_CUSTOMER, :P60_PHONE);
  END IF;
  PKG_PHARMACY.add_sale_item(:P60_SALE_ID, :P60_ITEM_ID, :P60_QTY, NVL(:P60_ITEM_DISC,0));
  SELECT NVL(SUM(QUANTITY*UNIT_PRICE),0), NVL(SUM(DISCOUNT_AMOUNT),0), NVL(SUM(LINE_TOTAL),0)
    INTO :P60_GROSS, :P60_DISC, :P60_NET
    FROM HMS_PHARMA_SALE_DTL WHERE SALE_ID = :P60_SALE_ID AND IS_ACTIVE='Y';
END;
```
Next true actions: Refresh `cart` → Clear P60_ITEM_ID, P60_QTY=1, P60_ITEM_DISC=0 (Set Value) → Set Focus P60_ITEM_ID.
Stock kom hole package error → DA automatically shows error notification.
Enter key on P60_QTY → trigger ADD: DA *Key Down*? → simpler: P60_QTY ▸ Settings ▸ Submit when Enter Pressed = No + JS page load:
`$('#P60_QTY').on('keydown',e=>{if(e.key==='Enter'){e.preventDefault();$('#ADD').click();}});` (Button Static ID `ADD`).

### Remove line — Ajax `REMOVE_LINE`
Stock deduct hoy sale line insert er somoy (trigger). Tai line muchle stock ferot dite hobe → **PR_PHARMA_REMOVE_LINE** (file `database/11_apex_support/04_pharmacy_cart.sql` — age HMS_APP e run korun).
Page ▸ JavaScript ▸ Function and Global Variable Declaration:
```javascript
function removeLine(id){
  apex.message.confirm('Ei medicine cart theke bad diben?', function(ok){
    if(!ok) return;
    apex.server.process('REMOVE_LINE',{x01:id,pageItems:'#P60_SALE_ID'},{
      success:function(d){
        $s('P60_GROSS',d.gross); $s('P60_DISC',d.disc); $s('P60_NET',d.net);
        apex.region('cart').refresh();
      }});
  });
}
```
Ajax Callback **REMOVE_LINE**:
```plsql
DECLARE l_g NUMBER; l_d NUMBER; l_n NUMBER;
BEGIN
  PR_PHARMA_REMOVE_LINE(TO_NUMBER(APEX_APPLICATION.G_X01));
  SELECT NVL(SUM(QUANTITY*UNIT_PRICE),0), NVL(SUM(DISCOUNT_AMOUNT),0), NVL(SUM(LINE_TOTAL),0)
    INTO l_g, l_d, l_n
    FROM HMS_PHARMA_SALE_DTL WHERE SALE_ID = :P60_SALE_ID AND IS_ACTIVE='Y';
  APEX_JSON.open_object; APEX_JSON.write('gross',l_g); APEX_JSON.write('disc',l_d); APEX_JSON.write('net',l_n);
  APEX_JSON.close_object;
END;
```
> Complete hoye gele remove na — Page 65 Return (PKG_PHARMACY.return_item).

### Complete
Button COMPLETE (Hot, large: Template Options ▸ Size Large, Width Stretch, fa-check) → Submit → Process:
```plsql
PKG_PHARMACY.finalize_sale(:P60_SALE_ID, NVL(:P60_PAID,0), :P60_PAY_MODE);
```
Validation: cart not empty (`EXISTS sale dtl`). OTC hole `PAID >= NET` validation; IPD hole paid 0 allowed (IPD bill e jabe — package handle kore).
Branch → Page 66 receipt print (`P66_SALE_ID`) → then Clear cache 60.
Button NEW_SALE / CANCEL → Clear Cache 60 → reload.

**Load Rx** (button): server code loop prescription lines → `add_sale_item(:P60_SALE_ID, item_id, quantity)` for lines with ITEM_ID (create sale first if null) → refresh.

## PAGE 66 — Pharmacy Receipt (Minimal, 80mm thermal)
CSS `@page{size:80mm auto;margin:2mm} body{font-size:11px;width:76mm}` · PL/SQL dynamic: shop header, sale no, date, items (name, qty × price = total), totals, paid, change, "Medicine ferot 7 din er moddhe" note.

---
## PAGE 63 — Stock Status
IR on `VW_PHARMA_STOCK_STATUS` (+ `WHERE STORE_ID IN (branch stores)`). Columns: STORE_NAME, ITEM_CODE, ITEM_NAME, GENERIC_NAME, TOTAL_QTY, REORDER_LEVEL, NEAREST_EXPIRY, STOCK_FLAG, EXPIRY_FLAG.
Highlight: OUT_OF_STOCK red row · LOW_STOCK orange · EXPIRING_90D yellow cell · EXPIRED red cell. Default saved report + alternative "Low stock" report (filter STOCK_FLAG<>'OK').
Drill: ITEM_NAME link → Page 631 (batch-wise modal: `HMS_PHARMA_STOCK WHERE ITEM_ID=... ORDER BY EXPIRY_DATE`).
Chart region (optional): Pie by STOCK_FLAG.

## PAGE 64 — Expiry Alert
Cards 64:
```sql
SELECT i.ITEM_NAME, s.BATCH_NO, s.EXPIRY_DATE, s.QTY_AVAILABLE, st.STORE_NAME,
       s.EXPIRY_DATE - TRUNC(SYSDATE) days_left,
       CASE WHEN s.EXPIRY_DATE <= TRUNC(SYSDATE) THEN 'u-danger'
            WHEN s.EXPIRY_DATE <= TRUNC(SYSDATE)+30 THEN 'u-warning' ELSE 'u-info' END css
  FROM HMS_PHARMA_STOCK s JOIN HMS_PHARMA_ITEM i ON i.ITEM_ID=s.ITEM_ID
  JOIN HMS_PHARMA_STORE st ON st.STORE_ID=s.STORE_ID
 WHERE s.QTY_AVAILABLE > 0 AND s.EXPIRY_DATE <= TRUNC(SYSDATE)+90 AND st.BRANCH_ID=:G_BRANCH_ID
 ORDER BY s.EXPIRY_DATE
```
Title ITEM_NAME · Subtitle `Batch &BATCH_NO. · Qty &QTY_AVAILABLE.` · Badge `&DAYS_LEFT. days` · CSS `&CSS.`. Facet: days bucket (30/60/90), store.

## PAGE 65 — Sale Return
Blank 65: P65_SALE_NO (Text + Search button) → report sale lines (`HMS_PHARMA_SALE_DTL` join sale where SALE_NO=:P65_SALE_NO) with column *Return* link → modal 651: P651_DTL_ID, P651_QTY (≤ sold − already returned), P651_REASON → `PKG_PHARMACY.return_item(:P651_DTL_ID, :P651_QTY, :P651_REASON);` → Close Dialog → refresh. Authorization AUTH_PHARMACY_ADD (approve role for > X Tk optional).

## Sprint 8 checklist
- [ ] Supplier/Store/Medicine (Sprint 3) → PO approve → GRN post → stock
- [ ] POS: search/scan, FEFO batch, stock kom error, complete, receipt
- [ ] IPD sale → IPD bill e line
- [ ] Stock / expiry reports · return → stock back
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Sale e stock nai | GRN POST hoyni ba batch expired |
| Cart theke remove e error | `04_pharmacy_cart.sql` run korun |
