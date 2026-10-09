# Page 95 / 951 — User Management (step by step)

**Hospital e kaj:** prottek karmochari nijer login (username+password) diye dhuke, shudhu nijer role er page dekhe. Page 95 = user list; 951 = notun user / edit / password reset / unlock.
**Shikhbo:** password hash (PKG_AUTH), many-to-many (user ↔ role), AUTH_SECURITY, LISTAGG.

## Step 0 — DB check (HMS_APP, Normal connect)
Roles 12, modules 22, users >= 1, `PKG_AUTH` VALID. Roles kom hole `database/08_master_data/06_seed_roles_modules.sql` (re-runnable) run korun.
(Toad e Connect as = **Normal**; SysDBA dile USER = SYS hoye jay.)

## Step 1 — Page 95 (Interactive Report), SQL: `03_SPRINT3_SETUP.md` Page 95 er SQL (STATUS_TXT/STATUS_CLS shoho, PASSWORD_HASH SELECT e nai).
Page Group `Setup`, Authorization `AUTH_SECURITY`, region Static ID `user_list`.

## Step 2 — Columns
1. USER_ID — pore (951 toiri hole Link).
2. USERNAME — Heading `Username`, HTML Expression `<span class="hms-code">#USERNAME#</span>`
3. EMPLOYEE_NAME — Heading `Employee`
4. ROLES — Heading `Roles`
5. LAST_LOGIN — Heading `Last Login`, Format Mask `DD/MM/YYYY HH24:MI`
6. FAILED_ATTEMPTS — Heading `Failed Attempts`, Alignment Center
7. STATUS_TXT — Heading `Status`, HTML Expression `<span class="hms-badge hms-st-#STATUS_CLS#">#STATUS_TXT#</span>`
8. STATUS_CLS — Hidden Column
Region ▸ Attributes ▸ Messages ▸ When No Data Found: `No users found. Click "Add User" to create one.`
(`hms-st-LOCK` = lal, `hms-st-Y` = shobuj, `hms-st-N` = dhushor; CSS e already ache.)

Step 3 (Page 951), Step 4 (buttons/processes) — porer step.

---
## Step 3 — Page 951 (Blank Page, modal) + items
**Keno Blank Page:** password hash kora lage (`PKG_AUTH.create_user`), tai Form wizard (table e sorasori INSERT) cholbe na. Items nijer haate banate hoy.

1. Create Page ▸ **Blank Page** · Number `951` · Name `User` · Page Mode **Modal Dialog** · Navigation: Don't use.
2. Page properties: Title `User` · Dialog ▸ Width `640` · Page Group `Setup` · Security ▸ Authorization `AUTH_SECURITY`.
3. Regions (Content Body ▸ Create Region, Static Content, Template **Blank with Attributes**): `Account` (seq 10), `Access` (seq 20).

**Region `Account` items**
1. P951_USER_ID — Hidden, seq 10
2. P951_USERNAME — Text Field, Label `Username`, Required On, Settings ▸ Text Case `Upper`, Read Only (Type Item is NOT NULL, Item P951_USER_ID), seq 20, new row Yes, span 12
3. P951_EMPLOYEE_ID — Select List, Label `Employee (optional)`, Null Display `- None -`, Required Off, seq 30, new row Yes, span 12:
```sql
SELECT e.EMPLOYEE_CODE || ' - ' || TRIM(e.FIRST_NAME || ' ' || e.LAST_NAME) d, e.EMPLOYEE_ID r
  FROM HMS_EMPLOYEE e
 WHERE e.IS_ACTIVE = 'Y'
   AND NOT EXISTS (SELECT 1 FROM HMS_USER u
                    WHERE u.EMPLOYEE_ID = e.EMPLOYEE_ID AND u.USER_ID <> NVL(:P951_USER_ID, -1))
 ORDER BY 1
```
4. P951_EMAIL — Text Field, Label `Email`, Placeholder `name@hospital.com`, seq 40, new row Yes, span 6
5. P951_MOBILE — Text Field, Label `Mobile`, Placeholder `01XXXXXXXXX`, seq 50, new row No, span 6
6. P951_PASSWORD — Password, Label `Password (min 8 characters)`, Required Off, Server-side Condition **Item is NULL** (P951_USER_ID), Settings ▸ Submit When Enter Pressed Off, seq 60, new row Yes, span 6
7. P951_PASSWORD_CONFIRM — Password, Label `Confirm Password`, same condition, seq 70, new row No, span 6

**Region `Access` items**
1. P951_ROLES — Checkbox Group, Label `Roles`, Required On, Number of Columns 2, seq 100, span 12:
```sql
SELECT ROLE_NAME d, ROLE_ID r FROM HMS_ROLE WHERE IS_ACTIVE = 'Y' ORDER BY ROLE_NAME
```
2. P951_IS_ACTIVE — Switch, Label `Active`, On `Y` / Off `N`, Default Static `Y`, Required Off, seq 110, span 6

Step 4: Load process, validations, buttons, processes — porer step.
