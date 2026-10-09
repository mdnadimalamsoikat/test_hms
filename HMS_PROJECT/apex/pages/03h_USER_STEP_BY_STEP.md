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
