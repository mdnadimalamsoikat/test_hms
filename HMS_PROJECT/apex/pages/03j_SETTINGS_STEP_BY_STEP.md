# Page 97 — System Settings (step by step)

> Design: **Interactive Grid NAY.** Classic Report (sundor list) + Modal Form (Edit/Add popup) — Department/Service/Medicine er moto.

## Page 97 ta ki — hospital e kon kaj
Admin code na chhuye system er setting badle: hospital er naam, VAT, MRN/Bill number kon prefix diye shuru, dropdown list, branch info + logo. 4 ta tab:

| Tab | Table | Hospital e ki | Real example |
|---|---|---|---|
| Config | HMS_SYSTEM_CONFIG | System er "rules" (key = value) | `MAX_DISCOUNT_PCT = 20` → approval chara 20% er beshi discount dewa jabe na; `IPD_MIN_ADVANCE = 5000` |
| Number Series | HMS_NUMBER_SERIES | Document number er format | MRN = `MRN-0000001` (kokhono reset hoy na); OPD = `OPD-00001` (protidin 1 theke) |
| Lookup | HMS_LOOKUP_MASTER | Dropdown er list | Blood group, Religion, Dosage form |
| Branch | HMS_BRANCH | Hospital/shakha er parichoy + logo | Naam, thikana, phone — report/print header e |

Page structure: **97** (4 tab list) + modal forms **971** Config, **972** Number Series, **973** Lookup, **974** Branch.

## Step 0 — DB check
```
SELECT 'branch' t, COUNT(*) c FROM HMS_BRANCH
UNION ALL SELECT 'config', COUNT(*) FROM HMS_SYSTEM_CONFIG
UNION ALL SELECT 'number_series', COUNT(*) FROM HMS_NUMBER_SERIES
UNION ALL SELECT 'lookup', COUNT(*) FROM HMS_LOOKUP_MASTER;
```
Expected: branch 1, config 7, number_series 21, lookup > 0. Also Shared Components ▸ Application Items ▸ `G_BRANCH_ID` thakte hobe.

## Step 1 — Page + Tabs Container
- Create Page ▸ **Blank Page**, 97, `System Settings`, Page Group `Setup`.
- Region `Settings Tabs`: Type **Static Content**, Appearance ▸ Template **Tabs Container** (Tabs Container region *type* na, *template*).
- Child region: Layout ▸ **Parent Region** = `Settings Tabs`; child er Title = tab label.

## Step 2 — Config tab (Classic Report)
Region `Config`: Type Classic Report · Layout ▸ Parent Region `Settings Tabs` · Appearance ▸ Template **Standard** (Blank with Attributes = header nai, button title er gaye lage) · CSS Classes `hms-wide` · Pagination No Pagination · No data: `No settings found. Click "Add Setting" to create one.`
```
select c.config_id,
       '<span class="hms-code">' || apex_escape.html(c.config_key) || '</span>' as config_key,
       c.config_value,
       c.config_desc,
       case c.is_active
         when 'Y' then '<span class="hms-badge hms-st-Y">Active</span>'
         else          '<span class="hms-badge hms-st-N">Inactive</span>'
       end as status_badge
  from hms_system_config c
 where c.branch_id = :G_BRANCH_ID
    or c.branch_id is null
 order by c.config_key
```
Columns: CONFIG_ID Link (pencil) · CONFIG_KEY `Setting` · CONFIG_VALUE `Value` · CONFIG_DESC `Description` · STATUS_BADGE `Status` — CONFIG_KEY & STATUS_BADGE **Escape special characters = No**. (`hms-card` class nai — dibenna.)

## Step 3 — Page 971 (modal form, Width 720)
Wizard Form ▸ Modal Dialog ▸ HMS_SYSTEM_CONFIG ▸ columns CONFIG_ID, BRANCH_ID, CONFIG_KEY, CONFIG_VALUE, CONFIG_DESC, IS_ACTIVE (audit 4 ta bad) · PK CONFIG_ID. Items: CONFIG_ID/BRANCH_ID Hidden (BRANCH_ID Default Item `G_BRANCH_ID`), CONFIG_KEY Text Field Required Text Case Upper, Read Only (Item is NOT NULL `P971_CONFIG_ID`), CONFIG_VALUE Text Field, CONFIG_DESC Textarea, IS_ACTIVE Switch Y/N default Y (Value Required Off). **Delete button muche din** (config delete korle program bhange). Validation `Setting key is unique` (NOT Exists):
```
select 1
  from hms_system_config
 where upper(config_key) = upper(:P971_CONFIG_KEY)
   and nvl(branch_id, -1) = nvl(:P971_BRANCH_ID, -1)
   and config_id <> nvl(:P971_CONFIG_ID, -1)
```
Error `This setting key already exists.` · Inline with Field and in Notification · Item `P971_CONFIG_KEY`. ARP Success Message khali + Execute Code process (ARP er pore, Close Dialog er ager):
```
apex_application.g_print_success_message :=
    'Setting <b>' || apex_escape.html(:P971_CONFIG_KEY) || '</b> saved successfully.';
```

## Step 4 — Page 97 wiring
CONFIG_ID Link (Page 971, Set Items `P971_CONFIG_ID`=`#CONFIG_ID#`, Clear Cache 971, Link Text `<span class="fa fa-edit" aria-label="Edit"></span>`, Escape No, Auth `AUTH_SETUP_EDIT`) · Button `ADD_CONFIG` (Slot Right of Title, Hot, `fa-plus`, **Action = Redirect to Page in this Application**, Page 971, Clear Cache 971, Auth `AUTH_SETUP_ADD`) · DA `Dialog Closed` (Region Config, Refresh) · Page 97 Auth `AUTH_SETUP`, Page 971 Auth `AUTH_SETUP_EDIT`.
**Problem:** Add Setting kaj kore na → button er default Action `Submit Page` chhilo; Redirect to Page 971 korte hobe.
**Problem:** table chhoto / button title er gaye → CSS v13 `.hms-wide` (Inline CSS fallback) + Template Standard.

## Step 5 — Number Series tab (list) + 5B tab design
Region `Number Series` (Classic Report, Standard, `hms-wide`, Parent `Settings Tabs`); SQL = series list with `next_number` = `prefix || lpad(current_no + 1, nvl(pad_length, 6), '0')`. Tab Title e icon + clear naam: `<span class="fa fa-sliders"></span> System Rules`, `<span class="fa fa-hashtag"></span> Document Numbers`. Region **Header Text** e `hms-note--info` box. Active tab er underline na — pill style: `hms.css` v14 (Page 97 ▸ CSS ▸ Inline e-o dewa jay).

## Step 6 — Page 972 Document Number (modal form, Width 720)
Wizard Form ▸ Modal Dialog ▸ HMS_NUMBER_SERIES ▸ columns SERIES_ID, BRANCH_ID, SERIES_TYPE, PREFIX, PAD_LENGTH, RESET_CYCLE, IS_ACTIVE (**CURRENT_NO, LAST_RESET_DATE ar audit 4 ta bad**). Items: SERIES_ID/BRANCH_ID Hidden (BRANCH_ID Default Item `G_BRANCH_ID`) · SERIES_TYPE Text Field Required Upper Read Only (Item is NOT NULL `P972_SERIES_ID`) · PREFIX Text Field Required Upper · PAD_LENGTH Number Field Required Min 3 Max 10 Default 6 · RESET_CYCLE Select List static (Never/NEVER, Yearly/YEARLY, Monthly/MONTHLY, Daily/DAILY) Default NEVER · IS_ACTIVE Switch Y/N Default Y. **`P972_CURRENT_NO`** Display Only, Source Type *SQL Query (return single value)* `select current_no from hms_number_series where series_id = :P972_SERIES_ID`, Used Always, Save Session State Off, Condition Item is NOT NULL `P972_SERIES_ID`. Caution region (`hms-note--warn`, seq 5). **Delete button muche din.** Validation `Document type is unique` (NOT Exists):
```
select 1
  from hms_number_series
 where upper(series_type) = upper(:P972_SERIES_TYPE)
   and branch_id = :P972_BRANCH_ID
   and series_id <> nvl(:P972_SERIES_ID, -1)
```
Success message process:
```
apex_application.g_print_success_message :=
    'Numbering for <b>' || apex_escape.html(:P972_SERIES_TYPE) || '</b> saved successfully.';
```
Kano `Last Used No.` read-only: Admin vul number dile same MRN duibar hote pare.

## Step 7 — Page 97 wiring (Number Series)
SERIES_ID Link (Page 972, Set Items `P972_SERIES_ID`=`#SERIES_ID#`, Clear Cache 972, pencil Link Text, Escape No, Auth `AUTH_SUPER`) · DA `Dialog Closed Number Series` (Region `Number Series`, Refresh) · Page 972 Auth `AUTH_SUPER` · Add button **nai** (number type gulo program e fixed). Test pore ekhon `UPDATE HMS_NUMBER_SERIES SET PREFIX='OPD-', PAD_LENGTH=5 WHERE SERIES_TYPE='OPD'; COMMIT;`

## Step 8–10 — Lookup tab (Dropdown Lists), Page 973
Tab region `Dropdown Lists` (Static Content, Standard, `hms-wide`, Parent `Settings Tabs`, Source Text = info note) · item `P97_LOOKUP_TYPE` (**Select List**, LOV `select initcap(replace(lookup_type,'_',' ')) d, lookup_type r from (select distinct lookup_type from hms_lookup_master) order by 1`, Display Null No, Default SQL `select min(lookup_type) from hms_lookup_master`) · sub region `Lookup Values` (Classic Report, Parent `Dropdown Lists`, Page Items to Submit `P97_LOOKUP_TYPE`, `where l.lookup_type = :P97_LOOKUP_TYPE`) · DA `Lookup list changed` (Change `P97_LOOKUP_TYPE` → Refresh `Lookup Values`) · DA `Dialog Closed Lookup`. Page 973 `Dropdown Value` (Delete button nai — Inactive use korun; `VW_LOV_LOOKUP` shudhu IS_ACTIVE='Y' dekhay).
Add button `ADD_LOOKUP` (region `Dropdown Lists`, Right of Title, Redirect Page 973, Clear Cache 973, **Set Items `P973_LOOKUP_TYPE` = `&P97_LOOKUP_TYPE.`**).
**Problem:** Add e `ORA-01400 ... HMS_LOOKUP_MASTER.LOOKUP_TYPE` → `P973_LOOKUP_TYPE` **Read Only = Always** item browser theke submit hoy na; Default dile screen e dekhay kintu session state e thake na → INSERT e NULL. Fix: Add button er Set Items e `P973_LOOKUP_TYPE`=`&P97_LOOKUP_TYPE.` (session state e boshe). Rule: **Read Only item er value save korte hole session state e thakte hobe (Set Items / Load process / Hidden item).**
