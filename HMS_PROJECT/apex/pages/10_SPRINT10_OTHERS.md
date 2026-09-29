# SPRINT 10 — Baki Module (150–250) + Go-Live Polish

🎯 **Ei sprint e ki hobe:** Baki module er plan + go-live er age final check.

## Shuru-r age (check)
- [ ] Sprint 1–9 complete
- [ ] Module er package lagle age amake bolun

**Build order:** Hospital er proyojon onujayi module (Emergency, OT, Blood Bank age sadharonoto)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

## A. Module build template (protiti module e 6 step)
1. **DB check**: `docs/TABLE_LIST.md` e module er table dekhun. Business rule (status change, stock, bill) thakle **age package** (amake bolun — `PKG_<MODULE>` baniye dibo). Simple master = direct DML OK.
2. **Menu**: HMS_APP_MODULE e APEX_PAGE_NO already set (150…250) → page banale menu kaj korbe. Authorization scheme `AUTH_<MODULE>` + `_ADD` banan (Sprint 1 pattern).
3. **Master pages**: Create Page ▸ IR + Modal Form (Sprint 3 pattern).
4. **Transaction page**: Blank page → Banner + Form + Summary (Sprint 4/5 pattern) → button → package call.
5. **Board / list**: Cards ba Faceted Search (status color).
6. **Print**: Minimal page + **Dynamic Content** region (PL/SQL Function Body returning a CLOB — Page 23 er moto `w()` + `RETURN l_html`).

## B. Module-wise plan
| Module | Pages | Main design |
|---|---|---|
| **Emergency 150** | 150 ER Board (Cards by triage: RED/YELLOW/GREEN css), 151 ER Registration (quick: name, age, gender, phone, complaint — unknown patient allowed → PKG_PATIENT with 'UNKNOWN'), 152 ER Treatment (vitals + notes + orders reuse), 153 Ambulance trips (IR+form, AMB_TRIP number) | Big buttons, minimum typing |
| **Radiology 160** | 160 Worklist (VW_LAB_PENDING where section RADIOLOGY), 161 Report Entry (**Rich Text Editor** item for findings/impression + template select), 162 Print | Order reuse Page 50 |
| **OT 170** | 170 OT Schedule (**Calendar**, OT room filter), 171 Booking form (surgeon, anaesthetist, procedure, date/time — conflict validation), 172 OT Notes (pre-op checklist switches, anaesthesia, surgery notes), 173 Consumables IG (→ IPD bill) | Calendar + checklist |
| **Blood Bank 180** | 180 Stock (Cards per blood group: A+ 12 bags…), 181 Donor (IR+form), 182 Collection/Bag entry (expiry auto +35d), 183 Request (from IPD), 184 Cross-match & Issue | Group-wise color cards |
| **Nursing 190** | 190 Ward Board (patients of my ward), 191 Nursing Assessment form, 192 Vitals chart entry (IG) + line chart, 193 Shift Handover (text per patient), 194 Med administration (Page 44 reuse) | Tablet-friendly (large items) |
| **Diet 200** | 200 Diet Orders (IPD patient → diet type LOOKUP), 201 Kitchen list (report by ward/meal time, print) | |
| **Accounts 210** | 210 Chart of Accounts (**Tree** region: `CONNECT BY PARENT`), 211 Journal Voucher (Master-Detail, debit=credit validation), 212 Ledger report (running balance), 213 Trial Balance | Voucher balance check |
| **Inventory 220** | 220 Items, 221 Indent (dept request), 222 Issue (approve → stock out), 223 Stock report | Pharmacy pattern |
| **HR 230** | 230 Employee (Page 91 reuse), 231 Attendance (IG per day), 232 Leave application + approval, 233 Payroll process (package lagbe), 234 Payslip print | Approval workflow |
| **Insurance 240** | 240 Companies, 241 Policies (patient link), 242 Claims (from bill, CLAIM number, status flow), 243 Claim report | |
| **Mortuary 250** | 250 Body Register (from IPD death discharge / ER), 251 Release form + print | |

## C. Go-Live Polish checklist (sob sprint shesh e)
**Security**
- [ ] Protiti page e Authorization (App Builder ▸ Utilities ▸ **Advisor** ▸ run → security warnings fix)
- [ ] Page Access Protection = Checksum (URL item page gula)
- [ ] Session Timeout: Application ▸ Security ▸ Maximum Session Idle Time **1800** sec
- [ ] Page 0 Session Info region delete · Debug off (Application ▸ Properties ▸ Debugging = No)
- [ ] Default ADMIN password change · test users delete
- [ ] Build Option `DEV_ONLY` banan → dev-only components e assign → production e Exclude

**UX**
- [ ] Sob list page e "No data found" message
- [ ] Sob delete e confirm · sob save e success message
- [ ] Required field star · Enter-as-tab kaj kore
- [ ] Print page A4/A5/80mm test (real printer)
- [ ] Mobile/tablet view check (Nursing, Doctor pages)

**Performance**
- [ ] Monitor Activity ▸ Page View Analysis → >2 sec page list → amake pathan (index/view tune)
- [ ] IR/Faceted: Pagination on, max rows limit
- [ ] Dashboard refresh interval 30–60s (kom na)

**Deployment**
- [ ] App export `f101.sql` + DB scripts Git e
- [ ] Production DB: RUN_ALL + 11_apex_support → APEX import → Parsing schema HMS_APP
- [ ] Backup schedule on (backup/ folder, SCHEDULE_TASKS.bat)
- [ ] UAT: protiti role er user diye 1 din full flow (Reception → Doctor → Lab → Pharmacy → Billing → IPD → Discharge)

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Module er page menu te nai | HMS_APP_MODULE.APEX_PAGE_NO + role permission check |
