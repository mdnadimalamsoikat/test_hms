# Page 96 — Role & Permission (step by step)

**Hospital e kaj:** Receptionist billing report dekhbe na, Pharmacist doctor er schedule bodlabe na. "Kon role kon module e ki korte parbe" ei page e thik hoy (View / Add / Edit / Delete / Print / Approve).
**Shikhbo:** Role → Permission → Module model (`HMS_ROLE`, `HMS_APP_MODULE`, `HMS_ROLE_PERMISSION`), Interactive Grid + PL/SQL MERGE save, Select List Submit Page.
**Dependency:** `database/08_master_data/06_seed_roles_modules.sql` (12 role, 22 module).

## Step 0 — DB check
```
SELECT r.ROLE_CODE, COUNT(rp.PERMISSION_ID) permissions
  FROM HMS_ROLE r LEFT JOIN HMS_ROLE_PERMISSION rp ON rp.ROLE_ID = r.ROLE_ID
 GROUP BY r.ROLE_CODE ORDER BY 1;
```
SUPER_ADMIN = 22, RECEPTION = 4, baki 0 (ei page diye bhorbo).

## Step 1 — Page + Role selector + note
1. Create Page ▸ Blank Page · Number `96` · Name `Role Permissions` · Page Mode Normal.
2. Page: Title `Role Permissions`, Page Group `Setup`, Security ▸ Authorization `AUTH_SUPER`.
3. Region `Select Role` (Static Content, Blank with Attributes, seq 10) ▸ item `P96_ROLE_ID` Select List, Label `Role`, Null `- Select a role -`, Page Action on Selection **Submit Page**, Required Off, span 4:
```
SELECT ROLE_NAME d, ROLE_ID r FROM HMS_ROLE
 WHERE IS_ACTIVE = 'Y' AND ROLE_CODE <> 'SUPER_ADMIN' ORDER BY ROLE_NAME
```
4. Region `Hint` (Static Content, Blank with Attributes, seq 20, Condition Item is NULL `P96_ROLE_ID`):
```
<div class="hms-note hms-note--info"><span class="fa fa-info-circle"></span><div><span class="hms-note-title">Select a role</span>Choose a role above to view and edit what it can do in each module. Users may need to sign in again for changes to apply.</div></div>
```

---
## Design decision: Interactive Grid NAY — manual matrix
IG er look/layout bhalo lage na, tai permission screen **Classic Report + apex_item checkbox** diye manually banano (CSS `hms-perm`, `hms.css` v12). Save = PL/SQL process (g_f01..g_f07 array → MERGE).
Rule: View chara Add/Edit/Delete/Print/Approve hoy na (JS + server dui jaygay-i enforce).

## Step 2 — Matrix region (Classic Report)
Region `Permissions` (Classic Report, Template Blank with Attributes, seq 30, CSS Classes `hms-perm`, Condition Item is NOT NULL `P96_ROLE_ID`). SQL:
```
SELECT apex_item.hidden(1, m.MODULE_ID)
       || '<span class="fa ' || NVL(m.ICON_CLASS, 'fa-cube') || ' hms-perm-ic"></span><span class="hms-perm-mod">'
       || apex_escape.html(m.MODULE_NAME) || '</span>'                                   AS MODULE_HTML,
       apex_item.checkbox2(2, m.MODULE_ID, NULL, CASE WHEN rp.CAN_VIEW    = 'Y' THEN TO_CHAR(m.MODULE_ID) END) AS C_VIEW,
       apex_item.checkbox2(3, m.MODULE_ID, NULL, CASE WHEN rp.CAN_ADD     = 'Y' THEN TO_CHAR(m.MODULE_ID) END) AS C_ADD,
       apex_item.checkbox2(4, m.MODULE_ID, NULL, CASE WHEN rp.CAN_EDIT    = 'Y' THEN TO_CHAR(m.MODULE_ID) END) AS C_EDIT,
       apex_item.checkbox2(5, m.MODULE_ID, NULL, CASE WHEN rp.CAN_DELETE  = 'Y' THEN TO_CHAR(m.MODULE_ID) END) AS C_DELETE,
       apex_item.checkbox2(6, m.MODULE_ID, NULL, CASE WHEN rp.CAN_PRINT   = 'Y' THEN TO_CHAR(m.MODULE_ID) END) AS C_PRINT,
       apex_item.checkbox2(7, m.MODULE_ID, NULL, CASE WHEN rp.CAN_APPROVE = 'Y' THEN TO_CHAR(m.MODULE_ID) END) AS C_APPROVE
  FROM HMS_APP_MODULE m
  LEFT JOIN HMS_ROLE_PERMISSION rp ON rp.MODULE_ID = m.MODULE_ID AND rp.ROLE_ID = TO_NUMBER(:P96_ROLE_ID)
 WHERE m.IS_ACTIVE = 'Y'
 ORDER BY m.DISPLAY_ORDER
```
Attributes: Pagination **No Pagination (Show All Rows)**. Columns: MODULE_HTML Heading `Module`; C_VIEW `View`; C_ADD `Add`; C_EDIT `Edit`; C_DELETE `Delete`; C_PRINT `Print`; C_APPROVE `Approve` — sob column **Escape special characters = No**.
Page ▸ JavaScript ▸ Execute when Page Loads: header "select all" + View-rule.

## Step 3 — Save
Region `Actions` (Static Content, Buttons Container, seq 40, Condition Item is NOT NULL P96_ROLE_ID): SAVE (`Save Permissions`, Next, Hot, Submit Page), DISCARD (`Discard Changes`, Previous, Redirect to Page 96, no Clear Cache). Process `Save permissions` (Execute Code, Processing, When Button Pressed SAVE) — code in chat/guide.
