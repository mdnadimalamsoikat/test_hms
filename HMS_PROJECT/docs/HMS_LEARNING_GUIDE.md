# HMS Learning Guide — ekta hospital kivabe kaj kore, ar amra keno ei page gulo banachhi

> Ei file porle bujhben: **kon page hospital er kon kaj kore**, **keno age-pore order**, ar **ki APEX/DB skill shikhchen**.
> Notun page build korar por ekhane "Ki shikhlam" part ta add hobe.

---
## 1. Hospital er puro golper shaptaho (1 bar porun)

```
 Reception          Doctor            Lab/Radiology      Ward (IPD)        Pharmacy        Billing
 ─────────          ──────            ─────────────      ──────────        ────────        ───────
 Patient register → Appointment/OPD → Test order      →  Admit, bed      → Medicine dey  → Bill, payment
 (MRN toiri)        Prescription      Report            Nursing, OT        Stock komey     Due, Discharge
```
Ekjon rogi ashle: **1) register (MRN)** → **2) doctor dekhe (OPD)**, fee lage → **3) test dey** (lab) → **4) bhorti hoy** (bed) → **5) oshudh pay** (pharmacy) → **6) sob khoroch ekta bill e**, tarpor discharge.

Ei golper **prottek dhape** kichu "ready thaka jinish" lage: doctor ache? fee koto? bed khali ache? oshudh stock e ache? Sei ready jinish gulo-i **Master / Setup data**. Eta **Sprint 3**.

> **Real-life rule:** age Master data, tarpor Transaction. Master chara transaction page (OPD, Billing) chalano jay na — dropdown faka thakbe.

---
## 2. Sprint onujayi map

### Sprint 1 — Foundation (login + common jinish)
- **Login, Authentication scheme, Application Items (`G_USER_ID`, `G_BRANCH_ID`...)**
  - *Keno:* hospital e onek user (receptionist, doctor, nurse, admin). Protijon nijer branch/role er data dekhbe. Login er por user er info session e rakhi.
  - *Shikhlam:* Session State, Application Item, Authentication vs Authorization.
- **Authorization Schemes (`AUTH_SETUP`, `AUTH_SECURITY`, `AUTH_SUPER`...)**
  - *Keno:* receptionist ke Settings page dekhano jabe na. Page/button/column — sob jaygay "ke dekhte parbe" alada thake.
  - *Shikhlam:* Security by role (DB te role → permission → APEX scheme), "Server-side security", UI hide korlei security na.
- **`hms.css`, `hms.js` (Static Application Files)**
  - *Keno:* sob page e ekoi look & feel; ek jaygay change korle puro app e change.
  - *Shikhlam:* Theme Roller vs custom CSS, `#APP_FILES#`, `#MIN#` (production e minified file).

### Sprint 2 — Patient (Page 11, 10, 12)
- **Page 11 Patient Search (Faceted Search):** Reception prothome rogi **khuje dekhe** (MRN/phone/name). *Keno:* duplicate patient toiri bondho korte age khuj. *Shikhlam:* Faceted Search, SQL view (`VW_PATIENT_SUMMARY`) diye page er SQL shohoj kora.
- **Page 10 Registration (Form):** notun rogi, MRN auto. *Shikhlam:* Form, validation (phone, DOB), Dynamic Action (age auto calc), duplicate check.
- **Page 12 Patient Profile:** ek rogir sob info (visits, due, allergy). *Shikhlam:* Display-only form, process diye data load, CSS class SQL theke (`u-danger-text` due hole).

### Sprint 3 — Setup / Master (Page 90–98) ← ekhon ekhane
- **Page 90/901 Department** — *Hospital e:* Medicine, Surgery, Cardiology... bivag. Doctor, ward, service sob kichu department er under. *DB:* `HMS_DEPARTMENT`. *Shikhlam:* Interactive Report + Modal Form pattern (**ei pattern baki sob page e repeat hoy**), KPI strip, Dialog Closed DA.
- **Page 91/911 Employee + Doctor + Schedule** — *Hospital e:* karmochari (doctor, nurse, staff). Doctor er **schedule** (kon din, kokhon) theke pore appointment slot toiri hoy. *DB:* `HMS_EMPLOYEE`, `HMS_DOCTOR`, `HMS_DOCTOR_SCHEDULE`. *Shikhlam:* auto code (DB trigger), LOV, Image upload, Interactive Grid (schedule), Authorization (Bank/TIN sudhu super admin).
- **Page 92/921/922 Service Master (+ Lab Parameter)** — *Hospital e:* ja ja bill kora jay: consultation fee, CBC test, X-ray, bed charge. Lab test e **parameter** (Hb, WBC) ar **normal range** (purush/nari/boyosh) thake, jeta report e dekhay. *DB:* `HMS_SERVICE_CATEGORY`, `HMS_SERVICE_MASTER`, `HMS_LAB_PARAMETER`, `HMS_LAB_REFERENCE_RANGE`. *Shikhlam:* Master-Detail, conditional show/hide (Dynamic Action), validation, tax/price design.
- **Page 93 Wards & Beds** — *Hospital e:* Ward (General/Cabin/ICU) → tar moddhe Bed. Admit er shomoy "khali bed" ekhan thekei ashe. *DB:* `HMS_WARD`, `HMS_BED`. *Shikhlam:* Master-Detail Interactive Grid, Query Only column, status badge.
- **Page 94/941 Medicine Master** — *Hospital e:* pharmacy r prescription er oshudh er list: naam, generic (Paracetamol), manufacturer, MRP. Generic diye doctor likhe, brand diye pharmacy dey. *DB:* `HMS_PHARMA_ITEM` + `_GENERIC`, `_CATEGORY`, `_MANUFACTURER`. *Shikhlam:* Select List LOV, price validation (MRP ≥ buy), duplicate check, success message process, default sort.
- **Page 95/951 User, 96 Role-Permission, 97 Settings, 98 Audit** *(pending)* — *Hospital e:* ke login korbe, ki korte parbe, system setting, ke kokhon ki bodlalo (audit = legal requirement).

### Porer sprint gulo (preview)
- **Sprint 4 OPD:** Appointment → Visit → Prescription (Sprint 3 er doctor, schedule, service, medicine **use hoy**).
- **Sprint 5 Billing:** Service + patient → bill, payment, due.
- **Sprint 6 IPD:** Admission → bed assign (Sprint 3 er bed) → discharge.
- **Sprint 7 Lab, 8 Pharmacy, 9 Reports, 10 Others.**

---
## 3. Ek dekhay "Page → Table → Hospital kaj" cheat-sheet
- List page (IR) = **dekhao + khuj + export** → table theke `SELECT`.
- Form page (modal) = **notun / edit** → `INSERT / UPDATE` (Automatic Row Processing).
- Grid (IG) = **onek row ekshathe edit** (schedule, bed, parameter).
- Dynamic Action = **page e click/change e browser e kichu hoy** (show/hide, refresh).
- Validation = **bhul data DB te dhukte debo na** (hospital e bhul data = rogir ghotona).
- Trigger = **DB nijei kore**, jeno kono page theke na gele-o rule thake (code, audit).
- Authorization = **ke dekhbe/korbe**.

## 4. Pattern 1 bar bujhle sob page shohoj
```
Region-1: List  (IR)    → SQL, column heading, badge, empty message
Page-2 : Form  (modal)  → items (LOV, validation), buttons (Save/Add/Cancel)
Link    : list → form   (Set Items = PK, Clear Cache)
DA      : Dialog Closed → list Refresh
Message : form process → success message
```
Department, Service, Medicine, User — sob-i ei 5 ta dhap. Tai ekta bujhle baki gulo **nijei** korte parben.

## 5. Nijeke test korar prosno (porer sprint er age)
1. Department delete na kore **Active switch** keno? *(jekhane onno table reference kore)*
2. `ITEM_CODE` auto keno **trigger** e, page process e na?
3. List e `ORDER BY` IR e keno kaj kore na?
4. Page e button hide korlei ki security hoy? Na hole ki kora lagbe?
5. Medicine form e `CATEGORY_ID` na hoye `PH_CATEGORY_ID` keno?
