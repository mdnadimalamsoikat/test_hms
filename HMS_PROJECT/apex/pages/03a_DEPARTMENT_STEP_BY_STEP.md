# Sprint 3 — Department (Page 90 + 901) — Ek ek step (APEX 24.2)

> Page Group `Setup` toiri hoye geche ✅. Ekhon thik ei order e korun. Kono step e atke gele **screenshot** pathan.

## PART 0 — ⚠️ Age ekbar DB fix (ORA-01400: cannot insert NULL into ...DEPT_ID / CREATED_DATE)
**Karon:** Table e `DEPT_ID DEFAULT SEQ_DEPARTMENT.NEXTVAL`, `CREATED_DATE DEFAULT SYSTIMESTAMP` — kintu APEX form insert e jei column er item ache tar value **NULL** pathay. Explicit NULL dile Oracle **DEFAULT use kore na** → ORA-01400.
(Trigger `TRG_AUDIT_COLUMNS` shudhu **UPDATE** e `UPDATED_BY/DATE` boshay. `CREATED_*` er jonno kono insert trigger nai — column DEFAULT i bharsha.)

**Fix 1 (DB, ekbar):** SQL Developer (HMS_APP) e `database/11_apex_support/07_default_on_null_ids.sql` **Run Script (F5)** — sob table er ID, CREATED_DATE, CREATED_BY, IS_ACTIVE (default thaka NOT NULL column) ke `DEFAULT ON NULL` banay. Output: `Done. Columns changed: N`.
Sudhu ei table e agey korte chaile: 
```sql
ALTER TABLE HMS_DEPARTMENT MODIFY (CREATED_DATE DEFAULT ON NULL SYSTIMESTAMP);
ALTER TABLE HMS_DEPARTMENT MODIFY (CREATED_BY   DEFAULT ON NULL NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER));
```
**Fix 2 (APEX, protiti form e):** Page 901 theke ei item gula **delete** korun (form e dekhanor dorkar nai, DB nijei bosay): `P901_CREATED_BY, P901_CREATED_DATE, P901_UPDATED_BY, P901_UPDATED_DATE`.
> Delete na korle **Edit/Save** e `ORA-01407 cannot update CREATED_DATE to NULL` ashbe.

## PART A — Page toiri (wizard)
1. App Builder ▸ **Application 101** ▸ **Create Page** (sobuj button).
2. Page type: **Report** ▸ **Interactive Report** ▸ Next.
3. Page Definition:
   | Field | Value |
   |---|---|
   | Page Number | `90` |
   | Name | `Departments` |
   | Page Mode | Normal |
   | Breadcrumb | Use Breadcrumb **Yes** (Breadcrumb: *Breadcrumb*, Parent Entry: *No parent*) |
   | **Include Form Page** (toggle) | **ON** |
   | Form Page Mode | **Modal Dialog** |
   | Form Page Number | `901` |
   | Form Page Name | `Department` |
   
   > *Include Form Page* na pele: Cancel ▸ Create Page ▸ **Form** ▸ **Report with Form** (ekoi kaj).
4. Next ▸ Navigation: **Navigation Menu ▸ Don't use** (HMS Menu dynamic) ▸ Next.
5. Data Source: **Table** ▸ Table/View `HMS_DEPARTMENT` ▸ Primary Key Column 1 **DEPT_ID**.
   Columns (Shuttle e sudhu ei 11 ta rakhun, baki CREATED_*/UPDATED_* **bad**):
   `DEPT_ID, BRANCH_ID, DEPT_CODE, DEPT_NAME, DEPT_TYPE, PARENT_DEPT_ID, HOD_EMPLOYEE_ID, FLOOR_NO, ROOM_NO, EXTENSION_NO, IS_ACTIVE`
6. Next ▸ **Create Page**. (Page 90 + 901 dutoi toiri hobe.)

## PART B — Page 90 (list) thik kora
Page 90 Page Designer e khulun (ba App Builder ▸ Page 90).

**B1. Page properties** — bame **Page 90** (sobar upore) click ▸ dane:
| Group | Property | Value |
|---|---|---|
| Identification | Title | `Departments` |
| Identification | Page Group | `Setup` |
| Security | Authorization Scheme | `AUTH_SETUP` |
| Security | Page Access Protection | Unrestricted (IR e ID pathate hobe na) |

**B2. Region SQL** — bame Rendering tree ▸ Body ▸ region `Departments` click ▸ dane **Source ▸ Type = SQL Query** ▸ **SQL Query** e ei ta (purono SQL muche):
```sql
SELECT d.DEPT_ID, d.DEPT_CODE, d.DEPT_NAME, d.DEPT_TYPE,
       p.DEPT_NAME PARENT_DEPT,
       TRIM(e.FIRST_NAME||' '||e.LAST_NAME) HOD,
       d.FLOOR_NO, d.ROOM_NO, d.EXTENSION_NO, d.IS_ACTIVE,
       CASE d.IS_ACTIVE WHEN 'Y' THEN 'Active' ELSE 'Inactive' END STATUS_TXT
  FROM HMS_DEPARTMENT d
  LEFT JOIN HMS_DEPARTMENT p ON p.DEPT_ID = d.PARENT_DEPT_ID
  LEFT JOIN HMS_EMPLOYEE  e ON e.EMPLOYEE_ID = d.HOD_EMPLOYEE_ID
 WHERE d.BRANCH_ID = :G_BRANCH_ID
```
Save (Ctrl+S). *Edit link ar column gula naam bodle jete pare — B3 e thik kora hobe.*

**B3. Column setting** — Rendering tree ▸ region ▸ **Attributes** ▸ Columns niche. Protita column e click:
| Column | Kora |
|---|---|
| DEPT_ID | Type **Link** ▸ Link ▸ Target: Page **901** ▸ Set Items `P901_DEPT_ID` = `#DEPT_ID#` ▸ Clear Cache **901** ▸ Link Text: `<span class="fa fa-edit" aria-label="Edit"></span>` ▸ Heading ` ` (faka) |
| DEPT_CODE | Heading `Code` |
| DEPT_NAME | Heading `Department` |
| DEPT_TYPE | Heading `Type` |
| PARENT_DEPT | Heading `Parent` |
| HOD | Heading `Head (HOD)` |
| FLOOR_NO / ROOM_NO / EXTENSION_NO | Heading `Floor` / `Room` / `Ext` |
| **IS_ACTIVE** | Type **Hidden Column** (Query Only) |
| **STATUS_TXT** | Heading `Status` ▸ Appearance ▸ **HTML Expression**: `<span class="hms-badge hms-st-#IS_ACTIVE#">#STATUS_TXT#</span>` |

(Jodi wizard DEPT_ID link age thekei kore rekhe thake, sudhu Link Text / Heading thik korun.)

**B4. Button** — Region e wizard er *Create* button ▸ Label `Add Department` ▸ Hot ✅ ▸ Icon `fa-plus` ▸ Action Redirect to Page **901** (Clear Cache 901) ▸ Security ▸ Authorization `AUTH_SETUP_ADD`.

**B5. Empty message** — region ▸ Attributes ▸ Messages ▸ When No Data Found: `Kono department nai. "Add Department" chepe notun toiri korun.`

**B6. Run** (▶) — list khali, **Add Department** button dekha jabe ✅.

## PART C — Page 901 (modal form) thik kora
Page Designer e Page **901**.

**C1. Page properties:**
| Group | Property | Value |
|---|---|---|
| Identification | Title | `Department` |
| Identification | Page Group | `Setup` |
| Dialog | **Width** | `720` |
| Security | Authorization Scheme | `AUTH_SETUP` |

**C2. Items** — Rendering tree ▸ region `Department` ▸ Items. Protita item click ▸ dane value din. **Sob item:** Appearance ▸ Template **Optional - Floating** (required gulo **Required - Floating**).
| Item | Type | Label | Kora |
|---|---|---|---|
| P901_DEPT_ID | Hidden | – | (wizard jemon ache) |
| P901_BRANCH_ID | Hidden | – | Default ▸ Type **Item** ▸ Item `G_BRANCH_ID` |
| P901_DEPT_CODE | Text Field | Code | Validation ▸ Value Required **On** ▸ Settings ▸ Text Case **Upper** ▸ Layout ▸ Start New Row **Yes** ▸ Column Span **4** |
| P901_DEPT_NAME | Text Field | Department Name | Value Required **On** ▸ Start New Row **No** ▸ Column Span **8** |
| P901_DEPT_TYPE | **Select List** | Type | List of Values ▸ Type **Static Values** ▸ (niche ta) ▸ Display Extra Values **Off** ▸ Null Display Value `- Select -` ▸ Start New Row Yes ▸ Span 6 |
| P901_PARENT_DEPT_ID | Select List | Parent Department | LOV Type **SQL Query** (niche) ▸ Null Display `- None -` ▸ Start New Row No ▸ Span 6 |
| P901_HOD_EMPLOYEE_ID | **Popup LOV** | Head of Dept | LOV SQL (niche) ▸ Display As **Modal Dialog** ▸ Start New Row Yes ▸ Span 12 |
| P901_FLOOR_NO | Text Field | Floor | Start New Row Yes ▸ Span 4 |
| P901_ROOM_NO | Text Field | Room | Start New Row No ▸ Span 4 |
| P901_EXTENSION_NO | Text Field | Extension | Start New Row No ▸ Span 4 |
| P901_IS_ACTIVE | **Switch** | Active | On Value `Y` ▸ Off Value `N` ▸ Default **Static** `Y` ▸ Start New Row Yes |

Static Values (P901_DEPT_TYPE) — *Add row* protitar jonno Display / Return:
`Clinical → CLINICAL` · `Non-Clinical → NON_CLINICAL` · `Diagnostic → DIAGNOSTIC` · `Admin → ADMIN` · `Support → SUPPORT` · `Pharmacy → PHARMACY` · `Lab → LAB`

P901_PARENT_DEPT_ID LOV SQL:
```sql
SELECT DEPT_NAME d, DEPT_ID r FROM HMS_DEPARTMENT
 WHERE BRANCH_ID = :G_BRANCH_ID AND DEPT_ID <> NVL(:P901_DEPT_ID,-1)
 ORDER BY 1
```
P901_HOD_EMPLOYEE_ID LOV SQL (employee ekhono nai, tai khali thakbe — thik ache):
```sql
SELECT TRIM(FIRST_NAME||' '||LAST_NAME)||' ('||EMPLOYEE_CODE||')' d, EMPLOYEE_ID r
  FROM HMS_EMPLOYEE WHERE IS_ACTIVE='Y' ORDER BY 1
```

**C3. Buttons** (wizard age theke ache — check):
| Button | Position | Kora |
|---|---|---|
| CANCEL | Close | Action **Defined by Dynamic Action** / *Cancel Dialog* |
| DELETE | Delete | Template Option **Danger** ▸ Condition `P901_DEPT_ID` Item is NOT NULL ▸ Authorization `AUTH_SUPER` |
| SAVE (Label `Save`) | Next | **Hot** ▸ Condition `P901_DEPT_ID` NOT NULL |
| CREATE (Label `Add Department`) | Next | **Hot** ▸ Condition `P901_DEPT_ID` IS NULL |

**C4. Validation** — Processing tab ▸ *Validating* ▸ right-click ▸ Create Validation:
- Name `Unique code` ▸ Type **No Rows returned** (SQL Query) ▸ Server-side Condition *When Button Pressed* CREATE/SAVE:
```sql
SELECT 1 FROM HMS_DEPARTMENT
 WHERE DEPT_CODE = :P901_DEPT_CODE AND BRANCH_ID = :G_BRANCH_ID
   AND DEPT_ID <> NVL(:P901_DEPT_ID,-1)
```
- Error message `Ei code age theke ache` ▸ Associated Item **P901_DEPT_CODE**.

**C5. Processes** — wizard jeta banay ta thik (Process form Department + Close Dialog). Shudhu check: Process er Server-side Condition *Button Pressed* kono ulta na.

## PART D — Page 90 e Dialog Closed
Page 90 ▸ Dynamic Actions tab (⚡) ▸ wizard age theke ekta **Dialog Closed** DA dey. Na thakle: *Dialog Closed* e right-click ▸ Create ▸ Name `Dialog Closed` ▸ Event **Dialog Closed** ▸ Selection Type **Region** ▸ Region `Departments` ▸ True Action **Refresh** (Region `Departments`).

## PART E — ✅ Test
1. Page 90 Run ▸ **Add Department**.
2. Code `OPD` · Name `Out Patient` · Type Clinical ▸ **Add Department** ▸ dialog bondho, list e dekha jabe (sobuj *Active* badge).
3. Pencil click ▸ Floor `1` ▸ Save.
4. Same code `OPD` abar ▸ error `Ei code age theke ache`.
5. Active switch off ▸ Save ▸ badge dhusor *Inactive*.

✅ 5 ta pass hole bolun — porer step e KPI strip (design) + Employee/Doctor.
