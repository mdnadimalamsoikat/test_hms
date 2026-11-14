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
## PAGE 70 — Bills List (Faceted Search + Classic Report)
**Kaj:** Cashier/reception current branch-er bill khujbe, type/status/due/period diye filter korbe, amount compare korbe. Ei page kono amount calculate/update kore na; bill amount-er source `PKG_BILLING`.

### Step 0 — Database view update/verify (APEX-er age)
`VW_BILL_LIST` ache `database/11_apex_support/03_apex_views.sql` file-e; **`RUN_ALL.sql` ei support file chalay na**. Updated file-ta **HMS_APP** diye ekbar run korun, nahole `DUE_ONLY`, `DUE_CSS`, `BILL_PERIOD` column paben na.

- **Toad:** `HMS_APP` connection select korun → `03_apex_views.sql` open korun → **F5 (Execute as Script)**.
- **SQL*Plus:** HMS_APP diye connect kore run korun: `@C:\HMS_PROJECT\database\11_apex_support\03_apex_views.sql` (project folder onno jaygay thakle `C:\HMS_PROJECT`-er jaygay nijer folder path din).

Page 70-er jonno `00_LOGIN_FIX.sql` abar chalanor dorkar nei. Login setup-e `00_LOGIN_FIX.sql` nijer moddhe `01_apex_support.sql` call kore; ei page-er notun view-column-gulor jonno ekhane **shudhu `03_apex_views.sql`** chalaben.

Tarpor HMS_APP diye ei check run korun:
```
SELECT OBJECT_NAME, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'VW_BILL_LIST';

SELECT COLUMN_NAME
  FROM USER_TAB_COLUMNS
 WHERE TABLE_NAME = 'VW_BILL_LIST'
   AND COLUMN_NAME IN ('DUE_ONLY','DUE_CSS','BILL_PERIOD')
 ORDER BY COLUMN_NAME;
```
Expected: `VW_BILL_LIST` = `VALID`, ebong second query-te 3-ta column.

**Date filter choice:** native `BILL_DATE` Range facet dibo na. Page 11/98-e ei dhoroner facet theke `ORA-01841` hoyechhilo. Tar bodole view-te safe text bucket ache: `1. Today`, `2. Last 7 days`, `3. Last 30 days`, `4. Older`. Ete APEX date-string parse korte hoy na. Page open hole kono bucket preselect thakbe na; current branch-er shob bill dekhabe.

### Step 1 — Create Page wizard
App Builder → App 101 → **Create Page** → **Component** tab → **Faceted Search**.

- Page Number: `70`
- Name: `Bills`
- Data Source: `Local Database`
- Source Type: `SQL Query`
- Query:
```
SELECT BILL_ID,
       BILL_NO,
       BILL_DATE,
       BILL_TYPE,
       MRN,
       PATIENT_NAME,
       PHONE_PRIMARY,
       NET_AMOUNT,
       PAID_AMOUNT,
       DUE_AMOUNT,
       DUE_ONLY,
       DUE_CSS,
       BILL_PERIOD,
       BILL_STATUS
  FROM VW_BILL_LIST
 WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY BILL_DATE DESC, BILL_ID DESC
```
Ei query-r kaj: `G_BRANCH_ID` diye signed-in user-er branch-er bill-i ashe; `DUE_ONLY` due filter-er jonno; `BILL_PERIOD` tarikh-ke text bucket kore; `DUE_CSS` shudhu positive due-ke red badge kore. `BILL_ID`, `DUE_ONLY`, `DUE_CSS`, `BILL_PERIOD` report-e hide thakbe, kintu link/filter/style-er jonno query-te thakbe.

Wizard-er **Navigation** group-e `Use Breadcrumb = Yes`, `Use Navigation = No` rakhun (HMS menu database theke ashe; ekhane menu banaben na). **Next** → **Display As = Report** (Cards na; taka-r column table-e pora shohoj) → Create Page. SQL Query source-e APEX automatic value-facet discover kore na; tai nicher Step 3-e amra 4-ta filter manually banabo.

### Step 2 — Page security + Faceted Search region
Page Designer-er Rendering tree-te **Page 70** select korun. Property Editor → **Security**:
- Authorization Scheme: `AUTH_BILLING`
- Page Access Protection: `Arguments Must Have Checksum`

Wizard-er `Search` region select korun → Property Editor → **Source** → `Filtered Region` = `Search Results` (ba wizard-e deya report region name) kina check korun. `Search` region-er **Attributes** tab → Settings → `Batch Facet Changes = Off` rakhun, jate checkbox-e tick dilei report refresh hoy; Apply button-e alada click lage na. Wizard-er Clear/Reset filter control thakle setai use korun; arekta reset button duplicate kore banaben na. Report region-er Type **Classic Report** thakbe, Interactive Grid noy.

### Step 3 — Filters (Search region-er `Facets` node)
`P70_SEARCH` wizard-e auto-toiri hoy. `P70_SEARCH` select kore Property Editor → **Source** → `Database Column(s)` e likhun:
`BILL_NO,MRN,PATIENT_NAME,PHONE_PRIMARY`
Eta bill number, MRN, patient name, phone—ei 4-ta column-e ek sathe text search kore.

`Search` region-er niche `Facets` node-te right-click → **Create Facet**. Prottek notun facet select kore Property Editor-er nicher properties din; `Name` field-e exact item name din:

- `P70_BILL_TYPE`: Identification → Name `P70_BILL_TYPE`, Type `Checkbox Group`; Label → Label `Bill Type`; Source → Database Column `BILL_TYPE`, Data Type `VARCHAR2`; List of Values → Type `Distinct Values`.
- `P70_BILL_STATUS`: Identification → Name `P70_BILL_STATUS`, Type `Checkbox Group`; Label → Label `Status`; Source → Database Column `BILL_STATUS`, Data Type `VARCHAR2`; List of Values → Type `Distinct Values`.
- `P70_BILL_PERIOD`: Identification → Name `P70_BILL_PERIOD`, Type `Checkbox Group`; Label → Label `Bill Period`; Source → Database Column `BILL_PERIOD`, Data Type `VARCHAR2`; List of Values → Type `Static Values`. Editor-e 4 row din, Display Value o Return Value prottek row-e same rakhun: `1. Today`; `2. Last 7 days`; `3. Last 30 days`; `4. Older`. Ete kono period-e ekhon bill na thakleo oi filter option-ta dekhabe.
- `P70_DUE_ONLY`: Identification → Name `P70_DUE_ONLY`, Type `Checkbox Group`; Label → Label `Due only`; Source → Database Column `DUE_ONLY`, Data Type `VARCHAR2`; List of Values → Type `Static Values`. `Static Values` select kore editor khulun; ek row add korun: Display Value `Due only`, Return Value `Y`. Tick korle sudhu positive due bill thakbe; untick korle shob bill thakbe.

### Step 4 — Classic Report columns
Rendering tree → **Search Results** report → **Columns**. `BILL_ID`, `DUE_ONLY`, `DUE_CSS`, `BILL_PERIOD` prottekta select kore Property Editor → **Identification** → `Type = Hidden` din. Hidden `BILL_ID` Page 71 link-er jonno, baki 3-ta filter/style-er jonno query-te thakbe; user-er chokhe dekhabe na.

Visible column-gulor **Heading → Heading** ei moto set korun: `BILL_NO` = `Bill #`; `BILL_DATE` = `Bill Date`; `BILL_TYPE` = `Type`; `PATIENT_NAME` = `Patient`; `MRN` = `MRN`; `PHONE_PRIMARY` = `Phone`; `NET_AMOUNT` = `Net (Tk)`; `PAID_AMOUNT` = `Paid (Tk)`; `DUE_AMOUNT` = `Due (Tk)`; `BILL_STATUS` = `Status`.

Page 71 create kore `P71_BILL_ID` item bananor por `BILL_NO` column → Identification → Type `Link` din → Link group-e `No Link Defined` click kore Link Builder khulun. Type `Page in this application`, Page `71`, Set Items-e Name `P71_BILL_ID`, Value `#BILL_ID#`, Clear/Reset → Clear Cache `71`; OK. Property Editor-er Link Text `#BILL_NO!HTML#` din. Page 71 age create na hole ei link config-ta pore korben, nahole item dropdown-e `P71_BILL_ID` thakbe na.

- `BILL_DATE`: Property Editor-er search box-e `Format Mask` type kore value `DD-MON-YYYY HH24:MI` din (24-hour time; example `30-SEP-2026 14:35`).
- `NET_AMOUNT`, `PAID_AMOUNT`, `DUE_AMOUNT`: prottek column-e search box-e `Format Mask` likhe `FM999G999G999G990D00` din. Mask-e 12 integer digit-er jayga ache, tai boro amount-o `#####` hoye jabe na. `FML` currency symbol NLS/database setting-er upor nirvor kore; heading-e `(Tk)` likhle taka-r label predictable thake.
- Prottek amount column-er **Heading → Alignment = Right** din—eta heading text align kore. APEX 24.2 Classic Report-er documented column properties-e data-cell alignment setting nishchit korte parini; tai oi unverified property khujte jaben na. Data value-ke HTML Expression-e `<span class="hms-money">...</span>` diye wrap korbo; paired `hms.css` / `hms.min.css`-er `.hms-money` rule cell-er width-er moddhe value dan dike align kore.
- `NET_AMOUNT` HTML Expression: `<span class="hms-money">#NET_AMOUNT!HTML#</span>`; `PAID_AMOUNT`: `<span class="hms-money">#PAID_AMOUNT!HTML#</span>`.
- `DUE_AMOUNT` HTML Expression: `<span class="hms-money"><span class="#DUE_CSS!ATTR#">#DUE_AMOUNT!HTML#</span></span>`. View-te positive due holei `DUE_CSS` = `hms-badge DUE`; zero due-te blank. Tai sudhu baki taka red badge hobe, paid bill-er `0.00` red hobe na.
- `BILL_STATUS`: `HTML Expression` din: `<span class="hms-badge #BILL_STATUS!ATTR#">#BILL_STATUS!HTML#</span>`. Ei charta column-er jonnoi **Security → Escape Special Characters = On** rakhun; expression-er HTML render hobe, ar database theke asha value-gulo `!HTML`/`!ATTR` diye safe bhabe escape hobe. `Escape Special Characters` Off korben na. `OPEN` blue, `PARTIAL` amber, `PAID` green, `CANCELLED` red, `REFUNDED` purple; `DRAFT` neutral gray.

Due/Status badge ebong amount alignment CSS APEX-e dekhate `Shared Components → Static Application Files`-e repo-r **dui file-i** replace korun: `apex/static/hms.css` and `apex/static/hms.min.css`. App-er CSS URL `#APP_FILES#static/hms#MIN#.css` hole normal run minified file use kore; update sheshe page run kore **Ctrl+F5** din.

`NET_AMOUNT`, `PAID_AMOUNT`, `DUE_AMOUNT` prottek column select → **Advanced** → `Compute Sum = On`. Eita report-er filtered rows-er sum; bill record-e kono update kore na.

Report region select korun → Property Editor → **Attributes** tab → `Messages` group-er `When No Data Found` e ei English message din: `No bills match the selected filters. Clear the filters or choose a different period.`

**CSV download (report-er built-in link):** Shared Components → **Globalization Attributes** → `Automatic CSV Encoding = On` kina check korun (default On). Page Designer-e **Search Results** region → Attributes tab → Appearance → Template `Standard` rakhun; Download group-e `CSV Export Enabled = On`, `Link Text = Download CSV`, `Filename = bills` set korun. `Supplemental Text` faka rakhun. Standard report template-er `#CSV_LINK#` slot diye link show hoy—alada Export button banaben na.
### Step 5 — Page 70 button
Prothome Rendering tree-te **Search Results** region select → Region property-er Appearance → `Template = Standard` din (header-er button slot thake). Tarpor Rendering tree → **Search Results** → **Buttons** right-click → **Create Button**. Button select kore Property Editor-e:
- Identification → Name `NEW_MISC_BILL`; Label `New Misc Bill`.
- Appearance → Button Template `Hot`; Icon `fa-plus`.
- Layout → Position **Edit** (Standard-template region header-er top-right; `Create` niben na, ota bottom-right-e jay).
- Security → Authorization Scheme `AUTH_BILLING_ADD` (bill dekhte `AUTH_BILLING`, notun bill khulte add permission lagbe).
- Behavior → Action `Redirect to Page in this Application`; Page `701`; Clear Cache `701`.

Page 701 ekhono create na hole button-er **target**-guilo 701 toiri howar por select korun; target set korar age button click kore test korben na. Page 701 Modal Dialog hole APEX dialog hisebe khulbe. CSV download-er jonno alada Export button lagbe na—Step 4-er report built-in link use korbe.

### ✅ Test — Page 70
1. Test user-er `G_BRANCH_ID`-er bill-guloi ashe kina dekhen; onnanno branch-er bill Page 70-e asha jabe na.
2. Bill no, MRN, patient name, phone-er kichu ongsho diye Search korun.
3. Type, Status, Bill Period, Due only alada kore tick/untick korun. `Due only` tick korle list-er prottek bill-er `DUE_AMOUNT > 0` hote hobe.
4. Net/Paid/Due mask, right alignment, due/status badge, filtered total-guloo verify korun.
5. `Download CSV` link thakle CSV download hoy kina test korun.
6. Page 71/701 toiri howar por Bill # link o `New Misc Bill` button test korun.

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
