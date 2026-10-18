# Page 98 — Audit Trail Viewer (step by step)

**Kaj:** kon record e ke, kokhon, ki bodlechhe (purono → notun). Read only, Auth `AUTH_SUPER`. Table `HMS_AUDIT_TRAIL`.
**Shotto kotha:** ekhon shudhu **HMS_PATIENT** change jomay (`TRG_AUDIT_PATIENT`). Onno table er jonno alada trigger lagbe; trigger dile ei page e nije ashbe.

## Step 0 — DB check
`SELECT COUNT(*) FROM HMS_AUDIT_TRAIL;` · `SELECT TRIGGER_NAME, STATUS FROM USER_TRIGGERS WHERE TRIGGER_NAME='TRG_AUDIT_PATIENT';` (ENABLED). Test data: Page 10 e patient er phone/blood group badle Save.

## Step 1 — Page
Create Page ▸ **Faceted Search** ▸ 98 `Audit Trail` ▸ Normal ▸ Table `HMS_AUDIT_TRAIL` ▸ PK `AUDIT_ID`. Page Group `Setup`, Authorization `AUTH_SUPER`.

## Step 2 — Results region (Classic Report)
Region `Audit Trail` (Classic Report, Blank with Attributes, CSS `hms-wide`, Pagination Row Ranges 25, Order By Clause `ACTION_TIME DESC, AUDIT_ID DESC`, No data `No audit records found for the selected filters.`):
```
select replace(to_char(a.action_time, 'DD Mon YYYY HH24:MI'), ' ', unistr('\00A0')) as when_txt,
       case a.action_type
         when 'INSERT' then '<span class="hms-badge hms-st-Y">Insert</span>'
         when 'UPDATE' then '<span class="hms-badge hms-st-WARN">Update</span>'
         when 'DELETE' then '<span class="hms-badge hms-st-LOCK">Delete</span>'
       end                                                                   as action_badge,
       initcap(replace(substr(a.table_name, 5), '_', ' '))                   as table_label,
       a.record_id,
       initcap(replace(a.column_name, '_', ' '))                             as column_label,
       case a.action_type
         when 'UPDATE' then
              '<span style="color:#9aa7b0;text-decoration:line-through">'
              || apex_escape.html(nvl(substr(a.old_value, 1, 100), '(empty)'))
              || '</span> &rarr; <b>'
              || apex_escape.html(nvl(substr(a.new_value, 1, 100), '(empty)')) || '</b>'
         when 'INSERT' then '<b>' || apex_escape.html(substr(a.new_value, 1, 100)) || '</b>'
         else '<span style="color:#9aa7b0;text-decoration:line-through">'
              || apex_escape.html(substr(a.old_value, 1, 100)) || '</span>'
       end                                                                   as change_html,
       a.action_by,
       a.ip_address,
       a.audit_id,
       a.table_name,
       a.action_type,
       a.action_time,
       a.module_name,
       a.old_value,
       a.new_value,
       case when a.action_time >= trunc(sysdate)       then 'Today'
            when a.action_time >= trunc(sysdate) - 6   then 'Last 7 days'
            when a.action_time >= trunc(sysdate) - 29  then 'Last 30 days'
            else 'Older' end                                                 as action_period
  from hms_audit_trail a
```
Visible columns: WHEN_TXT `When`, ACTION_BADGE `Action` (Escape No), TABLE_LABEL `Record Type`, RECORD_ID `Record #`, COLUMN_LABEL `Field`, CHANGE_HTML `Change` (Escape No), ACTION_BY `By`, IP_ADDRESS `IP Address`. Hidden: AUDIT_ID, TABLE_NAME, ACTION_TYPE, ACTION_TIME, MODULE_NAME, OLD_VALUE, NEW_VALUE, ACTION_PERIOD.
**Problem:** `When` column 4 line e bhenge jay → `unistr('\00A0')` (non-breaking space) diye space replace. **Problem:** date range facet `ORA-01841` → date ke text group (`ACTION_PERIOD`) kore checkbox facet.
