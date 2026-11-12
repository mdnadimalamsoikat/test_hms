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

---
## Step 4 — Page 951: load, validations, buttons, processes
**Extra item:** `P951_IS_LOCKED` — Hidden (Region Account, seq 15) — Unlock button condition er jonno.

**A. Load process** (Pre-Rendering ▸ Before Header ▸ Create Process) `Load user`, Execute Code, Server-side Condition ▸ Type **Expression**, Language **PL/SQL** (24.2 e "PL/SQL Expression" naam nai), Expression `:P951_USER_ID IS NOT NULL AND :P951_USERNAME IS NULL` (Clear Cache 951 er karone edit khulle USERNAME faka thake = load hoy; validation error e re-render hole USERNAME bhora = load hoy na, tai user er lekha value muche na. `:REQUEST IS NULL` er upor nirbhor kora jabe na):
```plsql
BEGIN
    SELECT USERNAME, EMPLOYEE_ID, EMAIL, MOBILE, IS_ACTIVE, IS_LOCKED
      INTO :P951_USERNAME, :P951_EMPLOYEE_ID, :P951_EMAIL, :P951_MOBILE, :P951_IS_ACTIVE, :P951_IS_LOCKED
      FROM HMS_USER WHERE USER_ID = :P951_USER_ID;
    SELECT LISTAGG(ROLE_ID, ':') WITHIN GROUP (ORDER BY ROLE_ID) INTO :P951_ROLES
      FROM HMS_USER_ROLE WHERE USER_ID = :P951_USER_ID AND IS_ACTIVE = 'Y';
END;
```
**B. Buttons** — region `Buttons` (Static Content, Slot Dialog Footer, Template Buttons Container): CANCEL (Close, Defined by Dynamic Action + DA Click → Cancel/Close Dialog), CREATE `Add User` (Next, Hot, Submit, Condition Item is NULL P951_USER_ID), SAVE `Save` (Next, Hot, Submit, Item is NOT NULL P951_USER_ID), RESET_PWD `Reset Password` (Previous, Redirect to URL `javascript:apex.confirm('Reset password to a temporary one?','RESET_PWD');`, Item is NOT NULL P951_USER_ID), UNLOCK `Unlock Account` (Previous, Submit, Execute Validations Off, Condition Item = Value P951_IS_LOCKED = Y).

**C. Validations** (Processing ▸ Validating):
1. `Username format` — Expression `REGEXP_LIKE(:P951_USERNAME, '^[A-Za-z0-9._-]{4,30}$')` · msg `Username must be 4-30 characters: letters, numbers, dot, underscore or hyphen.` · item P951_USERNAME · When Button Pressed CREATE
2. `Username unique` — No Rows returned `SELECT 1 FROM HMS_USER WHERE UPPER(USERNAME) = UPPER(TRIM(:P951_USERNAME)) AND USER_ID <> NVL(:P951_USER_ID, -1)` · msg `This username already exists.` · CREATE
3. `Password required` — Item is NOT NULL P951_PASSWORD · msg `Password is required.` · CREATE
4. `Password length` — Expression `:P951_PASSWORD IS NULL OR LENGTH(:P951_PASSWORD) >= 8` · msg `Password must be at least 8 characters.` · CREATE
5. `Passwords match` — Expression `:P951_PASSWORD = :P951_PASSWORD_CONFIRM` · msg `Passwords do not match.` · item P951_PASSWORD_CONFIRM · CREATE
6. `Email format` — Expression `:P951_EMAIL IS NULL OR REGEXP_LIKE(:P951_EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')` · msg `Enter a valid email address.`
7. `Mobile format` — Expression `:P951_MOBILE IS NULL OR REGEXP_LIKE(:P951_MOBILE, '^(\+?880)?01[3-9][0-9]{8}$')` · msg `Enter a valid mobile number, e.g. 01712345678.`
8. `Cannot deactivate yourself` — Expression `NOT (UPPER(:P951_USERNAME) = UPPER(:APP_USER) AND :P951_IS_ACTIVE = 'N')` · msg `You cannot deactivate your own account.` · item P951_IS_ACTIVE · Condition Item is NOT NULL P951_USER_ID

**D. Processes** (Processing ▸ Processing), all Execute Code:
1. `Create user` (seq 10, When Button Pressed CREATE):
```plsql
DECLARE
    l_id NUMBER;
BEGIN
    l_id := PKG_AUTH.create_user(
                p_username    => UPPER(TRIM(:P951_USERNAME)),
                p_password    => :P951_PASSWORD,
                p_branch_id   => :G_BRANCH_ID,
                p_employee_id => :P951_EMPLOYEE_ID,
                p_role_code   => NULL);
    :P951_USER_ID := l_id;
    UPDATE HMS_USER
       SET EMAIL = :P951_EMAIL, MOBILE = :P951_MOBILE, IS_ACTIVE = NVL(:P951_IS_ACTIVE, 'Y')
     WHERE USER_ID = l_id;
    apex_application.g_print_success_message :=
        'User ' || apex_escape.html(UPPER(TRIM(:P951_USERNAME))) || ' created. The user must change the password at first login.';
END;
```
2. `Update user` (seq 10, SAVE):
```plsql
BEGIN
    UPDATE HMS_USER
       SET EMPLOYEE_ID = :P951_EMPLOYEE_ID, EMAIL = :P951_EMAIL,
           MOBILE = :P951_MOBILE, IS_ACTIVE = :P951_IS_ACTIVE
     WHERE USER_ID = :P951_USER_ID;
    apex_application.g_print_success_message := 'User ' || apex_escape.html(:P951_USERNAME) || ' updated successfully.';
END;
```
3. `Save roles` (seq 20, Request is contained in Value `CREATE,SAVE`):
```plsql
BEGIN
    DELETE FROM HMS_USER_ROLE WHERE USER_ID = :P951_USER_ID;
    INSERT INTO HMS_USER_ROLE (USER_ID, ROLE_ID)
    SELECT :P951_USER_ID, TO_NUMBER(COLUMN_VALUE)
      FROM TABLE(APEX_STRING.SPLIT(:P951_ROLES, ':'));
END;
```
4. `Reset password` (seq 10, RESET_PWD) — NOTE: `PKG_AUTH.reset_password` FORCE_PWD_CHANGE='N' kore, tai porer UPDATE e abar 'Y':
```plsql
DECLARE
    l_pwd VARCHAR2(50) := 'Hms@' || TO_CHAR(SYSDATE, 'YYYY') || '-' || TRUNC(DBMS_RANDOM.VALUE(1000, 9999));
BEGIN
    PKG_AUTH.reset_password(:P951_USERNAME, l_pwd);
    UPDATE HMS_USER SET FORCE_PWD_CHANGE = 'Y' WHERE USER_ID = :P951_USER_ID;
    apex_application.g_print_success_message :=
        'Temporary password for ' || apex_escape.html(:P951_USERNAME) || ': <b>' || l_pwd ||
        '</b> (shown once - the user must change it at next login).';
END;
```
5. `Unlock account` (seq 10, UNLOCK):
```plsql
BEGIN
    UPDATE HMS_USER SET IS_LOCKED = 'N', FAILED_ATTEMPTS = 0 WHERE USER_ID = :P951_USER_ID;
    apex_application.g_print_success_message := 'Account ' || apex_escape.html(:P951_USERNAME) || ' unlocked.';
END;
```
6. `Close Dialog` (Type Close Dialog, seq 100, Request is contained in Value `CREATE,SAVE,RESET_PWD,UNLOCK`).

## Step 5 — Page 95: Edit link, Add User button, Dialog Closed DA
1. Column **USER_ID** ▸ Identification Type **Link** · Heading (ekta space) · Link ▸ Target: Type *Page in this Application*, Page `951`, Set Items `P951_USER_ID` = `#USER_ID#`, Clear Cache `951` · Link Text `<span class="fa fa-edit" aria-label="Edit"></span>`
2. Button (region Users ▸ slot *Right of Interactive Report Search Bar*): Label `Add User`, Hot On, Icon `fa-plus`, Action *Redirect to Page in this Application* ▸ Page `951`, Clear Cache `951`.
3. Dynamic Action: Name `Dialog Closed`, Event *Dialog Closed*, Selection Type *Region* = Users, True Action *Refresh* (Region Users).

## Step 6 — Test
1. Page 95: ADMIN row, shobuj `Active` badge, Roles = Super Administrator.
2. Add User: `reception1`, email, mobile, password `Hms@12345` (confirm same), Role `Receptionist / Front Desk` ▸ green message `User RECEPTION1 created...`, row list e.
3. Validation: duplicate username, password `abc`, mismatch, bad email/mobile, role chhara.
4. Edit (pencil): username read-only, password nai, roles tick loaded. Role bodle Save ▸ `updated successfully.`
5. Reset Password ▸ confirm ▸ message e temporary password ▸ oi password diye login ▸ Change Password page ashbe.
6. Lock: `UPDATE HMS_USER SET IS_LOCKED='Y' WHERE USERNAME='RECEPTION1'; COMMIT;` ▸ list e lal `Locked` ▸ open ▸ `Unlock Account` ▸ Active.
7. ADMIN edit ▸ Active off ▸ `You cannot deactivate your own account.`
8. RECEPTION1 rekhe din (Sprint 4 e receptionist hishebe test korbo).
