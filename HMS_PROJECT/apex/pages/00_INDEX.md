# HMS — APEX 24.2 Page-by-Page Build Manual

`PHASE2_APEX_GUIDE.md` = overview. **Ei folder = protiti page er click-by-click instruction.**
Ek file = ek sprint. Order e korun — porer page ager page er upor depend kore.

| File | Sprint | Pages |
|---|---|---|
| `01_SPRINT1_FOUNDATION.md` | Foundation | Shared Components, 0, 1, 2, 9999 |
| `02_SPRINT2_PATIENT.md` | Patient | 10, 11, 12 |
| `03_SPRINT3_SETUP.md` | Setup / Security | 90–98 |
| `04_SPRINT4_OPD.md` | Appointment + OPD | 3, 20, 21, 211, 22, 23, 30, 31 |
| `05_SPRINT5_BILLING.md` | Billing | 70, 701, 71, 72, 73 |
| `06_SPRINT6_IPD.md` | IPD | 40, 41, 42, 421, 43, 44, 45, 451 |
| `07_SPRINT7_LAB.md` | Lab | 50, 51, 52, 53, 54 |
| `08_SPRINT8_PHARMACY.md` | Pharmacy | 60, 61, 62, 63, 64, 65 |
| `09_SPRINT9_REPORTS.md` | Reports / MIS | 80–86 |
| `10_SPRINT10_OTHERS.md` | Baki module template | 150–250 |

---

## Kivabe porben (notation)

| Lekha | Mane |
|---|---|
| **Create Page ▸ Form** | App Builder ▸ App 101 ▸ **Create Page** button ▸ wizard e *Form* |
| `Region ▸ Appearance ▸ Template = Standard` | Page Designer e bame region select ▸ dane Property Editor ▸ *Appearance* group ▸ *Template* |
| `[Item] P10_GENDER` | Region er upor right-click ▸ **Create Page Item** ▸ Name = P10_GENDER |
| `[Button] SAVE` | Region right-click ▸ **Create Button** |
| `[DA]` | Bame **Dynamic Actions** tab (⚡) ▸ event er upor right-click ▸ Create |
| `[Process]` | Bame **Processing** tab (⚙) ▸ *Processing* er upor right-click ▸ Create Process |
| `[Validation]` | Processing tab ▸ *Validating* right-click ▸ Create Validation |
| `[Computation]` | Rendering tree ▸ *Pre-Rendering* ▸ right-click ▸ Create Computation |
| LOV SQL | Item ▸ *List of Values* ▸ Type = **SQL Query** ▸ paste |

### Protiti page e same 6 section
1. **Purpose** – page ki kore, ke use kore
2. **Create** – wizard e ki select
3. **Page properties** – mode, authorization, template
4. **Regions** – ek ek kore, sob property
5. **Items / Buttons / DA / Process / Validation**
6. **✅ Test** – ki korle bujhben page thik

### Protiti page shesh e (professional habit)
1. Page ▸ **Security ▸ Authorization Scheme** set (kokhono faka rakhben na)
2. Page ▸ **Security ▸ Page Access Protection = Arguments Must Have Checksum** (URL e ID bodle onner data dekha bondho)
3. Item jegula URL theke ashe (P12_PATIENT_ID) ▸ **Session State Protection = Checksum Required - Session Level**
4. Run ▸ Test ▸ **Save** ▸ Sprint shesh e export `f101.sql`

### Naming rule
- Item: `P<page>_<COLUMN>` (wizard nijei dey)
- Region Static ID: choto hater, `patient_banner`, `opd_queue` (JS/refresh e lage)
- Button: `SAVE`, `CREATE`, `DELETE`, `CANCEL`, `PRINT` (upper case, request name hoy)
- Process: kaj er naam — `Register Patient`, `Receive Payment`

App ID = **101** (apnar app).


## Files (sob ready)
| File | Pages |
|---|---|
| 01_SPRINT1_FOUNDATION.md | 9999, 1, 2, 0, auth schemes |
| 02_SPRINT2_PATIENT.md | 10, 11, 12 |
| 03_SPRINT3_SETUP.md | 90–99 |
| 04_SPRINT4_OPD.md | 30, 31, 20, 21, 211, 3, 22, 23 |
| 05_SPRINT5_BILLING.md | 70, 701, 71, 72, 73 |
| 06_SPRINT6_IPD.md | 41, 40, 42, 421, 43, 44, 45, 451 |
| 07_SPRINT7_LAB.md | 50, 51, 511, 54, 52, 53 |
| 08_SPRINT8_PHARMACY.md | 61/611, 62/621, 60 POS, 66, 63/631, 64, 65/651 |
| 09_SPRINT9_REPORTS.md | 80–86 |
| 10_SPRINT10_OTHERS.md | 150–250 plan + Go-Live checklist |

Extra DB file: `database/11_apex_support/04_pharmacy_cart.sql` (Sprint 8 er age run).
