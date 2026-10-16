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
