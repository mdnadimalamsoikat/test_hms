# SPRINT 6 — IPD (Page 41, 40, 42, 421, 43, 44, 45, 451)

🎯 **Ei sprint e ki hobe:** Bed map, admission, inpatient list, chart/medication, discharge.

## Shuru-r age (check)
- [ ] Sprint 3: Ward + Bed data
- [ ] Sprint 5 (IPD bill, advance)
- [ ] DB: `03_apex_views.sql` (VW_BED_MAP)

**Build order:** 41 → 40 → 42 → 421 → 43 → 44 → 45 → 451 (bed na dekhe admission hoy na)

**Protiti page e:** Create → Regions → Items → Buttons → DA → Process/Validation → ✅ Test. ✅ pass na hole porer page e jaben na.

> Guide er kono option screen e na pele → screenshot pathan, guide update kore dibo.

Flow: **Bed Map (41)** → **Admission (40)** → **Inpatients (42)** → **Chart (43) / Medication (44)** → **Discharge (45 → 451)**

---
## PAGE 41 — Bed Map ⭐
**Purpose:** Read-only bed status board. It shows every active bed in the signed-in user's branch and makes Available beds easy to find. Bed admission/status changes happen on later pages, not on this page.

### 1. Verify the views before opening Page Designer
Toad → connect as `HMS_APP` → run this check:
```
SELECT OBJECT_NAME, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME IN ('VW_BED_MAP', 'VW_BED_OCCUPANCY')
 ORDER BY OBJECT_NAME;
```
Both should be `VALID`. `VW_BED_MAP` is created by `database/11_apex_support/03_apex_views.sql`; `VW_BED_OCCUPANCY` is in `database/07_views/create_all_views.sql` (also called by `RUN_ALL.sql`). If a view is missing/invalid, open the corresponding file in Toad as HMS_APP and press **F5 (Execute as Script)**. The bed-map view already excludes inactive beds/wards; the Cards query below filters by `:G_BRANCH_ID`.

### 2. Create or update Page 41
If Page 41 already exists, update it—do not create a duplicate. Otherwise App Builder → App 101 → **Create Page** → **Component** → **Cards**; Page Number `41`, Name `Bed Map`, Data Source `Local Database`, Source Type `SQL Query`. Use the app's database-driven navigation (do not create a duplicate navigation menu).

Select Page 41 in Page Designer → Property Editor → **Security**:
- Authorization Scheme: `AUTH_IPD`
- Page Access Protection: `Arguments Must Have Checksum`

Select the **Bed Map** Cards region → Source → SQL Query:
```
SELECT BED_ID,
       WARD_ID,
       WARD_NAME,
       WARD_TYPE,
       FLOOR_NO,
       BED_NO,
       BED_TYPE,
       DAILY_CHARGE,
       BED_STATUS,
       STATUS_CSS,
       ADMISSION_ID,
       ADMISSION_NO,
       ADMISSION_DATE,
       MRN,
       PATIENT_NAME,
       CASE WHEN BED_STATUS = 'OCCUPIED'
            THEN NVL(PATIENT_NAME, 'Patient details unavailable')
            ELSE 'No patient assigned'
       END AS CARD_BODY,
       WARD_NAME || ' - ' || NVL(WARD_TYPE, 'Ward') ||
         CASE WHEN FLOOR_NO IS NOT NULL THEN ' - Floor ' || FLOOR_NO END
         AS CARD_SUBTITLE,
       CASE WHEN ADMISSION_ID IS NOT NULL
            THEN 'MRN ' || NVL(MRN, 'Not recorded') || ' - ' || ADMISSION_NO
            ELSE 'Bed type ' || NVL(BED_TYPE, 'Not set') ||
                 ' - Daily charge Tk ' ||
                 TO_CHAR(NVL(DAILY_CHARGE, 0), 'FM999G999G990D00')
       END AS CARD_META,
       CASE BED_STATUS
         WHEN 'AVAILABLE' THEN 'fa-bed'
         WHEN 'OCCUPIED'  THEN 'fa-user'
         WHEN 'RESERVED'  THEN 'fa-clock-o'
         ELSE 'fa-wrench'
       END AS ICON_CLASS
  FROM VW_BED_MAP
 WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY WARD_NAME, FLOOR_NO, BED_NO
```
This query only reads the existing view; it does not calculate a bill or update a bed. In the Cards region's **Attributes** tab, map the card fields to query columns: Title = `BED_NO`, Subtitle = `CARD_SUBTITLE`, Body = `CARD_BODY`, Secondary Body = `CARD_META`, Badge = `BED_STATUS`, Icon = `ICON_CLASS`, Card CSS Classes = `STATUS_CSS`. Set Layout to **Grid** (not Float), and Cards region → Appearance → CSS Classes = `hms-bed-map`. Keep the bed's status badge visible; the CSS class from the view supplies the status color.

### 3. Put ward occupancy above the bed cards
Create or keep a **Classic Report** named `Bed Occupancy by Ward`; no Interactive Grid. Its Source → SQL Query is:
```
SELECT WARD_NAME,
       TOTAL_BEDS,
       AVAILABLE,
       OCCUPIED,
       RESERVED,
       NOT_READY,
       OCCUPANCY_PCT
  FROM VW_BED_OCCUPANCY
 WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY WARD_NAME
```
Use headings `Ward`, `Total Beds`, `Available`, `Occupied`, `Reserved`, `Cleaning / Maintenance`, `Occupancy %`. Region → Appearance → CSS Classes = `hms-wide hms-bed-occupancy`; keep it full width. In Page Designer's Rendering tree, drag `Bed Occupancy by Ward` **above** `Bed Map` so the counts appear before the cards, not at the bottom of a long map.

Add a Static Content region named `Bed Status Note` above the Cards region. Source:
```
<div class="hms-note hms-note--info">
  <i class="fa fa-info-circle" aria-hidden="true"></i>
  <div>
    <span class="hms-note-title">Bed Status</span>
    <span>Available beds are ready for admission. Occupied, reserved, cleaning, and maintenance beds are not available.</span>
  </div>
</div>
```
The note and all card text are English. Do not add an insert/update process or editable page item to Page 41.

### 4. Test Page 41
Run as an IPD user and verify:
1. Only beds from the user's `G_BRANCH_ID` appear; no inactive bed/ward appears.
2. Available / Occupied / Reserved / Cleaning or Maintenance badges match the counts in `Bed Occupancy by Ward`.
3. Occupied cards show the patient name and MRN/admission number; unoccupied cards say `No patient assigned` and show the bed type/charge.
4. The page is read-only. The current build order is `41 → 40 → 42 → 421 → 43 → 44 → 45 → 451`; add the Available → Page 40 and Occupied → Page 43 card links only after those target pages exist. Reserved/cleaning/maintenance beds must not open admission.

If every card says `AVAILABLE`, check the occupancy report first. When `OCCUPIED = 0` for every ward, that is the database state—not a Cards styling error.
---
## PAGE 40 — Admission ⭐
**Purpose:** Create an inpatient admission, assign one currently available bed, open the IPD bill, and (if entered) record an advance payment. This is a **normal page**, not a modal and not an Automatic Row Processing form: the controlled transaction must go through `PKG_IPD.admit_patient`.

### 1. Check prerequisites in Toad
Connect as `HMS_APP` and verify the objects are valid:
```
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME IN ('VW_LOV_PATIENT', 'VW_LOV_DEPARTMENT', 'VW_LOV_DOCTOR',
                       'VW_LOV_LOOKUP', 'VW_BED_MAP', 'PKG_IPD', 'PKG_BILLING')
 ORDER BY OBJECT_TYPE, OBJECT_NAME;
```
Confirm `AUTH_IPD_ADD` exists under App Builder → App 101 → Shared Components → Security → Authorization Schemes. If it is missing, create it from the Sprint 1 authorization pattern with Scheme Type `Exists SQL Query` and:
```
SELECT 1 FROM DUAL WHERE PKG_APP_SESSION.can_yn('IPD', 'ADD') = 'Y'
```
Do not make a second scheme if it already exists.

### 2. Create or update Page 40
If Page 40 exists, update that page; do not create a duplicate. Otherwise App Builder → App 101 → **Create Page** → **Blank Page**. Set Page Number `40`, Name `Admission`, Page Mode `Normal`, Breadcrumb `Yes`, and do not add a duplicate navigation menu. A Blank Page is intentional: an Automatic Row Processing process would bypass the admission package and its bed lock, billing, and validations.

Select Page 40 in Page Designer → Property Editor → **Security**:
- Authorization Scheme: `AUTH_IPD_ADD`
- Page Access Protection: `Arguments Must Have Checksum`

In the Rendering tree, create these four **Static Content** regions using the `Standard` template: `Admission Safety Note` (first), `Patient & Visit` (12-column row), `Admission Details` (8 columns), and `Bed & Advance` (4 columns on the same row as Admission Details). On the Page Designer **Layout** tab, set `Admission Details` → Start New Row `Yes`; set `Bed & Advance` → Start New Row `No`. On a narrow screen APEX will stack the last two regions. Keep the existing page breadcrumb/title; do not create a second title region.

In `Admission Safety Note` → Source, paste this English user-facing note:
```
<div class="hms-note hms-note--warn">
  <i class="fa fa-exclamation-triangle" aria-hidden="true"></i>
  <div>
    <span class="hms-note-title">Before Admission</span>
    <span>Submitting this form admits the patient, allocates the selected bed, and opens an IPD bill. Verify the patient, doctor, and bed before continuing.</span>
  </div>
</div>
```

### 3. Add the page items
Create each item from the Page Designer **Rendering** tree. For a property that is hard to find, select the item and enter the property name in the Property Editor **Filter Properties** box; do not guess at a similarly named option.

- **P40_PATIENT_ID** — Region `Patient & Visit`; Type `Popup LOV`; Label `Patient`; Validation → Value Required `Yes`; LOV Type `SQL Query`; query:
```
SELECT D, R
  FROM VW_LOV_PATIENT
 WHERE BRANCH_ID = :G_BRANCH_ID
 ORDER BY D
```
  Set Display As `Modal Dialog`, Display Null Value `Yes`, Null Display Value `- Select patient (MRN - name - phone) -`, Manual Entry `No`, Fetch on Search `Yes`, Search Match Type `Contains`, and Minimum Characters `2`. (In APEX 24.2 the relevant property is Settings → Fetch on Search, not `Search as You Type`.) This branch-filtered LOV shows the MRN, patient name, and phone in the dialog. Security → Session State Protection `Unrestricted`: a Popup LOV saves its selection through Ajax and needs this item to accept that session-state update.

- **P40_OPD_VISIT_ID** — Region `Patient & Visit`; Type `Hidden`; Label is not displayed; Validation → Value Required `No`; Security → Session State Protection `Checksum Required - Session Level`. This optional value is passed only by the app-generated OPD admission link. Do not give it a user-editable LOV.

- **P40_DEPT_ID** — Region `Admission Details`; Type `Select List`; Label `Clinical Department`; Validation → Value Required `Yes`; LOV Type `SQL Query`:
```
SELECT D, R
  FROM VW_LOV_DEPARTMENT
 WHERE BRANCH_ID = :G_BRANCH_ID
   AND DEPT_TYPE = 'CLINICAL'
 ORDER BY D
```
  Display Null Value `Yes`; Null Display Value `- Select department -`; Security → Session State Protection `Unrestricted` (this is the parent value sent to the cascading Doctor LOV).

- **P40_DOCTOR_ID** — Region `Admission Details`; Type `Select List`; Label `Admitting Doctor`; Validation → Value Required `Yes`; LOV Type `SQL Query`:
```
SELECT D, R
  FROM VW_LOV_DOCTOR
 WHERE BRANCH_ID = :G_BRANCH_ID
   AND DEPT_ID = :P40_DEPT_ID
 ORDER BY D
```
  Display Null Value `Yes`; Null Display Value `- Select doctor -`; Cascading LOV Parent Item(s) `P40_DEPT_ID`; Security → Session State Protection `Unrestricted` (it is an editable cascading LOV item). Do not set a static doctor default. If this admission came from OPD, choose the treating doctor shown on that visit.

- **P40_ADMISSION_TYPE** — Region `Admission Details`; Type `Radio Group`; Label `Admission Type`; Validation → Value Required `Yes`; LOV Type `Static Values`; enter one entry per line:
```
Planned;PLANNED
Emergency;EMERGENCY
Transfer;TRANSFER
Day Care;DAY_CARE
Maternity;MATERNITY
```
  Default Type `Static`; Default `PLANNED`; keep the standard radio display style.

- **P40_REASON** — Region `Admission Details`; Type `Textarea`; Label `Reason for Admission`; Validation → Value Required `Yes`; Maximum Length `2000`; Rows `4`. The default required-field message comes from the English application text message.

- **P40_ATTENDANT_NAME** — Region `Admission Details`; Type `Text Field`; Label `Attendant Name`; Validation → Value Required `Yes`; Maximum Length `200`.

- **P40_ATTENDANT_PHONE** — Region `Admission Details`; Type `Text Field`; Label `Attendant Phone`; Validation → Value Required `Yes`; Maximum Length `50`. Keep it a text field so a leading zero or `+880` is not lost.

- **P40_BED_ID** — Region `Bed & Advance`; Type `Popup LOV`; Label `Available Bed`; Validation → Value Required `Yes`; LOV Type `SQL Query`:
```
SELECT v.WARD_NAME || ' - Bed ' || v.BED_NO || ' (' ||
       NVL(v.BED_TYPE, 'Standard') || ', Tk ' ||
       TO_CHAR(NVL(v.DAILY_CHARGE, 0), 'FM999G999G990D00') || '/day)' AS D,
       v.BED_ID AS R
  FROM VW_BED_MAP v
  JOIN HMS_WARD w ON w.WARD_ID = v.WARD_ID
 WHERE v.BRANCH_ID = :G_BRANCH_ID
   AND v.BED_STATUS = 'AVAILABLE'
   AND ( :P40_PATIENT_ID IS NULL
         OR EXISTS (
              SELECT 1
                FROM HMS_PATIENT p
               WHERE p.PATIENT_ID = :P40_PATIENT_ID
                 AND p.BRANCH_ID = :G_BRANCH_ID
                 AND p.IS_ACTIVE = 'Y'
                 AND (w.GENDER_ALLOWED = 'ALL' OR w.GENDER_ALLOWED = p.GENDER)
         )
       )
 ORDER BY v.WARD_NAME, v.BED_NO
```
  Set Display As `Modal Dialog`, Display Null Value `Yes`, Null Display Value `- Select an available bed -`, Cascading LOV Parent Item(s) `P40_PATIENT_ID`, and Security → Session State Protection `Unrestricted`. The Popup LOV and patient cascade update session state through Ajax. With no patient selected (for example, when Page 41 passes a bed), the LOV lists this branch's available beds. Once a patient is selected it refreshes to beds allowed for that patient's gender. If the previously selected bed is no longer eligible, select another one. The package locks and checks the bed again at submit time, so two users cannot admit into the same bed.

- **P40_ADVANCE** — Region `Bed & Advance`; Type `Number Field`; Label `Advance (Tk)`; Validation → Value Required `No`; Default Type `Static`; Default `0`. In the Property Editor search for `Format Mask` and set `FM999G999G990D00`; the page validation below rejects negative values.

- **P40_PAYMENT_MODE** — Region `Bed & Advance`; Type `Select List`; Label `Advance Payment Mode`; Validation → Value Required `Yes`; Default Type `Static`; Default `CASH`; LOV Type `SQL Query`:
```
SELECT D, R
  FROM VW_LOV_LOOKUP
 WHERE LOOKUP_TYPE = 'PAYMENT_MODE'
 ORDER BY DISPLAY_ORDER
```
  This mode is used only when Advance is greater than zero; Cash remains the safe default.

- **P40_ADMISSION_ID** — Region `Patient & Visit`; Type `Hidden`; Validation → Value Required `No`; Security → Session State Protection `Restricted - May not be set from browser`; process output item. Do not display or let the user edit it.
- **P40_ADMISSION_NO** — Region `Patient & Visit`; Type `Hidden`; Validation → Value Required `No`; Security → Session State Protection `Restricted - May not be set from browser`; process output item used in the success message. Do not display or let the user edit it.

For items supplied by a link (Patient ID, Bed ID, or OPD Visit ID), use APEX's **Redirect to Page in this Application** target and set the target items there; do not hand-build a URL. Set Clear Cache to `40` on each link to remove values from an earlier admission. Keep Page Access Protection `Arguments Must Have Checksum`; this page-level checksum protects incoming link arguments even though the editable LOV items below use `Unrestricted` item protection.

**ORA-20987 / `ajax_set_session_state` fix:** Popup LOV and cascading LOV values are written to APEX session state by Ajax. If `P40_PATIENT_ID`, `P40_DEPT_ID`, `P40_DOCTOR_ID`, or `P40_BED_ID` reports that no session checksum was passed, select that item → Property Editor → Security → Session State Protection → `Unrestricted`, then Save. Do not weaken the page's `Arguments Must Have Checksum` setting. Keep `P40_OPD_VISIT_ID` at `Checksum Required - Session Level` because only an APEX-generated link sets it; keep the two admission output items at `Restricted - May not be set from browser`. Branch, patient, doctor, and bed validations still enforce the allowed values on submit.

### 4. Add the Admit button
In the Page Designer Gallery → **Buttons**, drag a button into the `Bed & Advance` region. Set Name `ADMIT`, Label `Admit Patient`, Position `Create` (the bottom-right region position), Action `Submit Page`, Button Template `Hot`, Icon `fa-bed`, and Behavior → Requires Confirmation `Yes` with message `Admit this patient to the selected bed and create an IPD bill?`. Set Show Processing `Yes` to discourage a second click. The button must execute validations; do not turn off Execute Validations.

### 5. Add validations (all messages must remain English)
Open the **Processing** tab on the left → right-click **Validations** → **Create Validation**. For each validation set Identification → Name; Execution Options → Sequence and Always Execute `No`; Validation → Type and SQL Query; Error → Error Message, Display Location, and Associated Item; Server-side Condition → Type `When Button Pressed`, Button `ADMIT`. For `Rows Returned` / `No Rows Returned`, the Validation Type uses a SQL Query; APEX 24.2 does not show a separate Language property for these SQL validations, so do not search for one. Use `Inline with Field and in Notification` for item errors and `Inline in Notification` for the optional hidden OPD visit check. Language applies to the later Execute Code process, where it is `PL/SQL`. These checks only provide a helpful message; the package still performs the final locked bed check.

1. Name `Patient belongs to this branch`; Sequence `10`; Type `Rows Returned`; SQL Query:
```
SELECT 1
  FROM DUAL
 WHERE :P40_PATIENT_ID IS NULL
    OR EXISTS (
         SELECT 1
           FROM VW_LOV_PATIENT
          WHERE R = :P40_PATIENT_ID
            AND BRANCH_ID = :G_BRANCH_ID
       )
```
   Error Message `Select an active patient from this branch.`; Display Location `Inline with Field and in Notification`; Associated Item `P40_PATIENT_ID`.

2. Name `Doctor and department are valid`; Sequence `20`; Type `Rows Returned`; SQL Query:
```
SELECT 1
  FROM DUAL
 WHERE :P40_DOCTOR_ID IS NULL
    OR :P40_DEPT_ID IS NULL
    OR EXISTS (
         SELECT 1
           FROM VW_LOV_DOCTOR d
           JOIN VW_LOV_DEPARTMENT dep ON dep.R = d.DEPT_ID
          WHERE d.R = :P40_DOCTOR_ID
            AND d.BRANCH_ID = :G_BRANCH_ID
            AND d.DEPT_ID = :P40_DEPT_ID
            AND dep.BRANCH_ID = :G_BRANCH_ID
            AND dep.DEPT_TYPE = 'CLINICAL'
       )
```
   Error Message `Select an active doctor from the chosen clinical department.`; Display Location `Inline with Field and in Notification`; Associated Item `P40_DOCTOR_ID`.

3. Name `Bed is still available and suitable`; Sequence `30`; Type `Rows Returned`; SQL Query:
```
SELECT 1
  FROM DUAL
 WHERE :P40_PATIENT_ID IS NULL
    OR :P40_BED_ID IS NULL
    OR EXISTS (
         SELECT 1
           FROM VW_BED_MAP v
           JOIN HMS_WARD w ON w.WARD_ID = v.WARD_ID
           JOIN HMS_PATIENT p ON p.PATIENT_ID = :P40_PATIENT_ID
          WHERE v.BED_ID = :P40_BED_ID
            AND v.BRANCH_ID = :G_BRANCH_ID
            AND v.BED_STATUS = 'AVAILABLE'
            AND p.BRANCH_ID = :G_BRANCH_ID
            AND p.IS_ACTIVE = 'Y'
            AND (w.GENDER_ALLOWED = 'ALL' OR w.GENDER_ALLOWED = p.GENDER)
       )
```
   Error Message `That bed is unavailable or not suitable for this patient. Choose another available bed.`; Display Location `Inline with Field and in Notification`; Associated Item `P40_BED_ID`.

4. Name `Patient has no active admission`; Sequence `40`; Type `No Rows Returned`; SQL Query:
```
SELECT 1
  FROM HMS_IPD_ADMISSION
 WHERE PATIENT_ID = :P40_PATIENT_ID
   AND ADMISSION_STATUS IN ('ADMITTED', 'DISCHARGE_INITIATED')
```
   Error Message `This patient already has an active admission.`; Display Location `Inline with Field and in Notification`; Associated Item `P40_PATIENT_ID`. This matches the duplicate check inside `PKG_IPD`.

5. Name `Linked OPD visit belongs to this patient`; Sequence `50`; Type `No Rows Returned`; SQL Query:
```
SELECT 1
  FROM DUAL
 WHERE :P40_OPD_VISIT_ID IS NOT NULL
   AND NOT EXISTS (
         SELECT 1
           FROM HMS_OPD_VISIT v
          WHERE v.VISIT_ID = :P40_OPD_VISIT_ID
            AND v.PATIENT_ID = :P40_PATIENT_ID
            AND v.BRANCH_ID = :G_BRANCH_ID
            AND v.IS_ACTIVE = 'Y'
            AND v.VISIT_STATUS IN ('IN_CONSULTATION', 'COMPLETED')
       )
```
   Error Message `The linked OPD visit does not belong to this patient or cannot be admitted.`; Display Location `Inline in Notification`; Associated Item: leave blank (the OPD Visit ID item is Hidden). This validation passes when the optional OPD Visit ID is null.

6. Name `Advance cannot be negative`; Sequence `60`; Type `No Rows Returned`; SQL Query:
```
SELECT 1 FROM DUAL WHERE NVL(:P40_ADVANCE, 0) < 0
```
   Error Message `Advance must be zero or greater.`; Display Location `Inline with Field and in Notification`; Associated Item `P40_ADVANCE`.

For these nine required items (`P40_PATIENT_ID`, `P40_DEPT_ID`, `P40_DOCTOR_ID`, `P40_ADMISSION_TYPE`, `P40_REASON`, `P40_ATTENDANT_NAME`, `P40_ATTENDANT_PHONE`, `P40_BED_ID`, `P40_PAYMENT_MODE`), set Validation → Value Required `Yes`. APEX 24.2 uses the application text message `APEX.PAGE_ITEM_IS_REQUIRED` for its built-in required error; keep the application language/message English rather than looking for a per-item `Value Required Message` property. Optional `P40_OPD_VISIT_ID` and `P40_ADVANCE` remain Value Required `No`.

### 6. Add the admission process and return branch
On the **Processing** tab, right-click **Processes** → **Create Process**. Set Identification → Name `Admit Patient`, Type `Execute Code`; Source → Location `Local Database`, Language `PL/SQL`, and paste the code below; Execution → Point `Processing`, Sequence `10`; Server-side Condition → Type `When Button Pressed`, Button `ADMIT`. Leave Success Message → Success Message blank: the code sets a success message only after the package succeeds. Error messages from the two package race checks are added inline by the code; unexpected errors are re-raised to APEX.
```
DECLARE
  l_admission_no VARCHAR2(30);
BEGIN
  APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := NULL;
  :P40_ADMISSION_ID := PKG_IPD.admit_patient(
    p_branch_id       => :G_BRANCH_ID,
    p_patient_id      => :P40_PATIENT_ID,
    p_doctor_id       => :P40_DOCTOR_ID,
    p_dept_id         => :P40_DEPT_ID,
    p_bed_id          => :P40_BED_ID,
    p_admission_type  => :P40_ADMISSION_TYPE,
    p_reason          => :P40_REASON,
    p_opd_visit_id    => :P40_OPD_VISIT_ID,
    p_attendant_name  => :P40_ATTENDANT_NAME,
    p_attendant_phone => :P40_ATTENDANT_PHONE,
    p_advance_amount  => NVL(:P40_ADVANCE, 0),
    p_payment_mode    => NVL(:P40_PAYMENT_MODE, 'CASH'),
    p_admission_no    => l_admission_no
  );

  :P40_ADMISSION_NO := l_admission_no;
  APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE :=
    'Admission ' || APEX_ESCAPE.HTML(l_admission_no) || ' created successfully.';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20301 THEN
      APEX_ERROR.ADD_ERROR(
        p_message          => 'This patient already has an active admission.',
        p_display_location => APEX_ERROR.C_INLINE_WITH_FIELD_AND_NOTIF,
        p_page_item_name   => 'P40_PATIENT_ID',
        p_ignore_ora_error => TRUE
      );
    ELSIF SQLCODE = -20302 THEN
      APEX_ERROR.ADD_ERROR(
        p_message          => 'The selected bed is no longer available. Choose another bed.',
        p_display_location => APEX_ERROR.C_INLINE_WITH_FIELD_AND_NOTIF,
        p_page_item_name   => 'P40_BED_ID',
        p_ignore_ora_error => TRUE
      );
    ELSE
      RAISE;
    END IF;
END;
```
Do not add an Automatic Row Processing process or a second INSERT. `PKG_IPD.admit_patient` creates the admission and IPD bill, updates the linked OPD visit (when supplied), records a positive advance, and locks/re-checks the bed. The exception block turns the package's duplicate-patient and bed-race errors into clear English inline messages; unexpected errors are re-raised for APEX's normal error handling.

Create a Branch named `Return to Bed Map`; Point `After Processing`; Type `Page or URL (Redirect)`; Target Page `41`; Clear Cache `41`; Server-side Condition → Type `When Button Pressed`, Button `ADMIT`. Page 42 is built next; after it exists and is tested, the successful admission branch can be changed to the agreed inpatient destination. Page 41 is the safe test destination now because it shows that the bed changed to Occupied.

### 7. Test Page 40 before moving on
This is a real database write even on a test run: admission creates an IPD bill and changes the selected bed to Occupied. Use a test patient and a test/development database; set Advance to `0` unless deliberately testing an advance receipt.

1. Page Designer → Page 40 → **Save**, then click **Run**. This is a normal page, so it can be run directly; it is not a modal dialog.
2. Open the Patient LOV and select a test patient. Choose a clinical department and its active doctor, then choose an available bed suitable for that patient's gender. Fill Admission Type, Reason, Attendant Name/Phone; keep Advance `0` and Payment Mode `Cash` for the first test.
3. Click **Admit Patient** and confirm. The page should return to Page 41 with an English success message. The selected bed should now show `OCCUPIED`; ward counts should increase by one occupied bed and decrease by one available bed.
4. Before submitting, also test that a missing required field shows its English inline error; a bed that is no longer Available is rejected; a patient with an existing `ADMITTED` or `DISCHARGE_INITIATED` admission is rejected; and a linked OPD visit from another patient/branch is rejected. No failed validation may create an admission or bill.
5. If the test fails, keep the exact APEX error text and screenshot. Do not click Admit again until checking the patient's admission and the bed status in Toad.

---
## PAGE 42 — Current Inpatients
Interactive Report 42 on `VW_IPD_CURRENT_PATIENTS WHERE BRANCH_ID=:G_BRANCH_ID`
Columns: ADMISSION_NO, ADMISSION_DATE, STAY_DAYS, MRN, PATIENT_NAME, GENDER, WARD_NAME, BED_NO, DOCTOR_NAME, BILL_AMOUNT, PAID_AMOUNT, DUE_AMOUNT, ADVANCE_BALANCE
- DUE_AMOUNT > ADVANCE_BALANCE → red highlight (Actions ▸ Format ▸ Highlight, condition expression)
- Control break WARD_NAME (default saved)
- **Actions column** (24.2): add virtual column `ACTIONS` → Type *Link* with HTML `<button class="t-Button t-Button--small js-menuButton" data-menu="adm_menu_#ADMISSION_ID#">⋮</button>` — simpler: 4 link icon columns:
  | Column (SQL: NULL AS ...) | Icon | Target |
  |---|---|---|
  | CHART | fa-heartbeat | 43 `P43_ADMISSION_ID=#ADMISSION_ID#` |
  | MEDS | fa-medkit | 44 |
  | BILL | fa-money | 71 `P71_BILL_ID` = `PKG_IPD.get_ipd_bill_id(ADMISSION_ID)` (add as SQL column IPD_BILL_ID) |
  | TRANSFER | fa-exchange | 421 |
  | DISCHARGE | fa-sign-out | 45 |
Authorization AUTH_IPD.

## PAGE 421 — Bed Transfer (Modal 520)
Items: P421_ADMISSION_ID (hidden) · P421_CURRENT (Display: current ward/bed) · P421_BED_ID (Popup, available beds) · P421_REASON (Required).
Process `PKG_IPD.transfer_bed(:P421_ADMISSION_ID, :P421_BED_ID, :P421_REASON, :G_EMPLOYEE_ID);` → Close Dialog. Parent refresh.

---
## PAGE 43 — IPD Patient Chart
Blank 43 ▸ Hidden P43_ADMISSION_ID (checksum), P43_PATIENT_ID (load).
**Banner** (Value Attribute Pairs row): `SELECT ADMISSION_NO, PATIENT_NAME, MRN, WARD_NAME||' / '||BED_NO bed, DOCTOR_NAME, STAY_DAYS||' days' stay, DUE_AMOUNT FROM VW_IPD_CURRENT_PATIENTS WHERE ADMISSION_ID=:P43_ADMISSION_ID`
Buttons in banner: Medication (44), Lab Order (50 with admission), Bill (71), Transfer (421), Discharge (45).
**Tabs Container**:
| Tab | Region |
|---|---|
| Doctor Rounds | IG `HMS_IPD_DOCTOR_VISIT WHERE ADMISSION_ID=:P43_ADMISSION_ID ORDER BY VISIT_TIME DESC` — ADMISSION_ID default item, DOCTOR_ID default `(SELECT DOCTOR_ID FROM HMS_DOCTOR WHERE EMPLOYEE_ID=:G_EMPLOYEE_ID)`, VISIT_TIME default SYSTIMESTAMP, VISIT_TYPE select (ROUTINE/CALL/EMERGENCY/CONSULTANT), PROGRESS_NOTES textarea, INSTRUCTIONS, VISIT_CHARGE (read-only; bill posting chaile IG after-save process e `PKG_BILLING.add_bill_item(PKG_IPD.get_ipd_bill_id(:P43_ADMISSION_ID), NULL,'Doctor visit',1,:VISIT_CHARGE,0,:DOCTOR_ID,'IPD_VISIT',:IPD_VISIT_ID)`) |
| Vitals | Line chart from nursing vitals table (Sprint 10 Nursing) — placeholder |
| Lab Results | Report: orders with ADMISSION_ID = :P43_ADMISSION_ID + link to 53 |
| Medication | Read-only summary of active HMS_IPD_MEDICATION (edit on 44) |
| Charges | Classic: `HMS_BILLING_DTL WHERE BILL_ID = PKG_IPD.get_ipd_bill_id(:P43_ADMISSION_ID)` + button *Post today's bed charge* → `PKG_IPD.post_bed_charges(:P43_ADMISSION_ID);` |

## PAGE 44 — Medication Chart
Blank 44. Region 1 **Medication Orders** IG `HMS_IPD_MEDICATION WHERE ADMISSION_ID=:P44_ADMISSION_ID`:
ITEM_ID (Popup VW_LOV_MEDICINE) → MEDICINE_NAME, DOSAGE, ROUTE (LOOKUP), FREQUENCY (LOOKUP), START_DATE (default today), END_DATE, ORDERED_BY (default employee), ORDER_STATUS (Select ACTIVE/STOPPED/COMPLETED), INSTRUCTIONS. Authorization edit: AUTH_DOCTOR.
Region 2 **Administration (Nurse)** IG master-detail (detail of region 1): `HMS_IPD_MED_ADMINISTRATION` — SCHEDULED_TIME, GIVEN_TIME (default now), GIVEN_BY (default employee), ADMIN_STATUS (GIVEN/MISSED/REFUSED/HELD), NOTES.
Create both via **Create Page ▸ Master Detail ▸ Side by Side**? — admission filter lagbe tai Blank + 2 IG, detail IG ▸ Master Region = region 1.

---
## PAGE 45 — Discharge (Wizard style)
Blank 45 ▸ P45_ADMISSION_ID. Region **Wizard Progress** (Static, List template *Wizard Progress*, list static: Summary → Bill → Confirm) — optional look.
**Region 1 Discharge Summary** — Form region on `HMS_DISCHARGE_SUMMARY` (PK SUMMARY_ID; load where ADMISSION_ID via pre-rendering select SUMMARY_ID into item):
DISCHARGE_TYPE (Select NORMAL/LAMA/REFERRED/DEATH/ABSCONDED/DOR), FINAL_DIAGNOSIS, ICD_ID (popup), TREATMENT_GIVEN (Textarea/Rich Text), PROCEDURES_DONE, CONDITION_AT_DISCHARGE, DISCHARGE_ADVICE, DISCHARGE_MEDICATION (Textarea — "copy from active medication" button: server code `SELECT LISTAGG(MEDICINE_NAME||' '||DOSAGE||' '||FREQUENCY, CHR(10)) ... INTO :P45_DISCHARGE_MEDICATION`), FOLLOWUP_DATE, ADMISSION_ID (hidden default), DISCHARGED_BY (default employee), SUMMARY_STATUS (DRAFT/FINAL).
Button SAVE_SUMMARY (ARP).
**Region 2 Bill Status**: before showing → Pre-Rendering `PKG_IPD.post_bed_charges(:P45_ADMISSION_ID);` then Value pairs: Net, Paid, Advance, **Due**. Button `Go to Bill` → 71.
**Region 3 Confirm**: P45_ALLOW_DUE (Switch, Authorization AUTH_SUPER) · Button DISCHARGE (Hot, Danger confirm "Patient discharge korben?"):
```plsql
PKG_IPD.discharge_patient(:P45_ADMISSION_ID, :P45_DISCHARGE_TYPE, NVL(:P45_ALLOW_DUE,'N'));
UPDATE HMS_DISCHARGE_SUMMARY SET SUMMARY_STATUS='FINAL' WHERE ADMISSION_ID=:P45_ADMISSION_ID;
```
Due thakle package `-20305 Due ache...` → user notification e dekhbe. Success → Branch 451.

## PAGE 451 — Discharge Summary Print
Minimal template, **Dynamic Content** region (PL/SQL Function Body returning a CLOB — Page 23 er moto `w()` + `RETURN l_html`) (page 23 technique): hospital header, patient + admission (date in/out, ward/bed, consultant), final dx, treatment, procedures, condition, **discharge medication** table, advice, follow-up, doctor signature. A4.

## Sprint 6 checklist
- [ ] Bed map color · admit from free bed → bed red
- [ ] Round note, medication, transfer (old bed free, new occupied)
- [ ] Bed charge post → bill · Discharge with due block · print
- [ ] Export + commit

## Problem hole (quick fix)
| Problem | Fix |
|---|---|
| Bed map khali | HMS_BED e data/IS_ACTIVE='Y' nai |
| Discharge e ORA-20305 | Due ache — payment nin ba ALLOW_DUE (AUTH_SUPER) |
