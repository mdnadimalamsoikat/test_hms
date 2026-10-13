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

---
### Step 2 JavaScript (Page ▸ JavaScript ▸ Execute when Page Loads)
```
(function () {
  var $t = $(".hms-perm table.t-Report-report").first();
  if (!$t.length) { return; }
  var others = "input[name='f03'],input[name='f04'],input[name='f05'],input[name='f06'],input[name='f07']";
  $t.find("th").each(function (i) {
    if (i === 0) { return; }
    var name = "f0" + (i + 1);
    var $all = $('<input type="checkbox" class="hms-perm-all" title="Select all" aria-label="Select all" style="display:block;margin:6px auto 0;">');
    $all.on("change", function () {
      $t.find("input[name='" + name + "']").prop("checked", this.checked).trigger("change");
    });
    $(this).append($all);
  });
  $t.on("change", others, function () {
    if (this.checked) { $(this).closest("tr").find("input[name='f02']").prop("checked", true); }
  });
  $t.on("change", "input[name='f02']", function () {
    if (!this.checked) { $(this).closest("tr").find(others).prop("checked", false); }
  });
})();
```
### Step 3 process `Save permissions` (Execute Code, PL/SQL, When Button Pressed SAVE)
```
DECLARE
    l_role NUMBER := TO_NUMBER(:P96_ROLE_ID);
    l_name HMS_ROLE.ROLE_NAME%TYPE;

    FUNCTION is_on (p_arr IN apex_application_global.vc_arr2, p_mod IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        FOR i IN 1 .. p_arr.COUNT LOOP
            IF p_arr(i) = p_mod THEN RETURN 'Y'; END IF;
        END LOOP;
        RETURN 'N';
    END is_on;
BEGIN
    FOR i IN 1 .. apex_application.g_f01.COUNT LOOP
        DECLARE
            l_mod  VARCHAR2(30) := apex_application.g_f01(i);
            l_add  VARCHAR2(1)  := is_on(apex_application.g_f03, l_mod);
            l_edit VARCHAR2(1)  := is_on(apex_application.g_f04, l_mod);
            l_del  VARCHAR2(1)  := is_on(apex_application.g_f05, l_mod);
            l_prn  VARCHAR2(1)  := is_on(apex_application.g_f06, l_mod);
            l_apr  VARCHAR2(1)  := is_on(apex_application.g_f07, l_mod);
            l_view VARCHAR2(1);
        BEGIN
            l_view := CASE WHEN is_on(apex_application.g_f02, l_mod) = 'Y'
                             OR 'Y' IN (l_add, l_edit, l_del, l_prn, l_apr)
                           THEN 'Y' ELSE 'N' END;
            MERGE INTO HMS_ROLE_PERMISSION t
            USING (SELECT l_role AS ROLE_ID, TO_NUMBER(l_mod) AS MODULE_ID FROM DUAL) s
               ON (t.ROLE_ID = s.ROLE_ID AND t.MODULE_ID = s.MODULE_ID)
             WHEN MATCHED THEN UPDATE SET
                  t.CAN_VIEW = l_view, t.CAN_ADD = l_add, t.CAN_EDIT = l_edit,
                  t.CAN_DELETE = l_del, t.CAN_PRINT = l_prn, t.CAN_APPROVE = l_apr, t.IS_ACTIVE = 'Y'
             WHEN NOT MATCHED THEN INSERT
                  (ROLE_ID, MODULE_ID, CAN_VIEW, CAN_ADD, CAN_EDIT, CAN_DELETE, CAN_PRINT, CAN_APPROVE)
                  VALUES (s.ROLE_ID, s.MODULE_ID, l_view, l_add, l_edit, l_del, l_prn, l_apr);
        END;
    END LOOP;
    SELECT ROLE_NAME INTO l_name FROM HMS_ROLE WHERE ROLE_ID = l_role;
    apex_application.g_print_success_message :=
        'Permissions saved for role ' || apex_escape.html(l_name) || '. Users may need to sign in again.';
END;
```

---
## Problems amra ja face korechi (shob solved)
| Problem | Karon | Fix |
|---|---|---|
| Matrix e shudhu 15 row | Classic Report pagination 15 | Region ▸ Attributes ▸ Pagination ▸ Type **No Pagination (Show All Rows)**. Pagination on thakle `apex_item` array e shudhu dekhano row thake, Save baki module ke 'N' kore dey |
| Label "Role Id" | APEX item name theke auto label | `P96_ROLE_ID` ▸ Label ▸ Label = `Role` |
| Receptionist er default tick nei | Partial matrix theke Save → seed permission 'N' hoye gechhe | DELETE RECEPTION rows + INSERT Y/Y/Y/Y (DASHBOARD, PATIENT, APPOINTMENT, OPD) + COMMIT |
| Header e tick-all checkbox ashe na | Region er **prothom `<table>`** = `t-Report-pagination`, asol matrix `table.t-Report-report` | JS e `$(".hms-perm table.t-Report-report")` |
| Design change hoy na (v12) | Static file replace hoyni / selector | `hms.css` + `hms.min.css` duita replace + Ctrl+F5; na hole **Page ▸ CSS ▸ Inline** e v12 block |
| Header checkbox cell er checkbox er sathe mele na | Header e checkbox lekhar bame (`prepend`) | `append` + `display:block; margin:6px auto 0` (lekha upore, checkbox niche, majhkhane) |

## Console diagnostics (pore kaje lagbe)
- Chrome Console e paste block: prothome hate `allow pasting` type korun.
- `document.querySelector('.hms-perm table').className` — kon table dhorche dekhar jonno.
- Static file thik kina: Static Application Files ▸ size: `hms.css` ~18.5 KB, `hms.min.css` ~14.1 KB.

## Part E — code ta ki kore (jate nijeo likhte paren)
1. **`apex_item.checkbox2(p_idx=>2, p_value=>module_id, p_attributes=>...)`** — report er protiti row te ekta checkbox banay. `p_idx` = array number (`f02` = View). Submit er por `apex_application.g_f02` e shudhu **tick kora** row er value ashe.
2. **`f01` hidden (`apex_item.hidden`)** — protiti row er MODULE_ID. Tick na kora checkbox submit hoy na, tai amra f01 theke "shob module" ar f02..f07 theke "tick kora module" mila-i.
3. **JS tick-all** — header `th` e `<input>` bosay, change e oi column er shob `input[name=f0N]` ke `checked` kore.
4. **View auto-tick rule** — Add/Edit/Delete/Print/Approve tick dile oi row er View tick; View tulle baki shob untick. Karon View chhara onno right er mane nei.
5. **Save process** — protiti module (f01) er jonno `is_on(f0N, module)` dekhe 'Y'/'N' ber kore **MERGE INTO HMS_ROLE_PERMISSION** (thakle update, na thakle insert). Server e-o View='Y' force kore (JS bypass hole-o thik thake).
6. **Condition `P96_ROLE_ID IS NOT NULL`** — role na bachle matrix dekhabe na (Save-er jonno role lagbei).
