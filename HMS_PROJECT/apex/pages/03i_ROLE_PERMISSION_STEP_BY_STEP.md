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
