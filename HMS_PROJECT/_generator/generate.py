# -*- coding: utf-8 -*-
"""Generates sequence / table / index / FK / comment scripts from tables_def.py
Run:  python generate.py      (output -> ../database/...)
"""
import os, re, sys, datetime
sys.path.insert(0, os.path.dirname(__file__))
from tables_def import MODULES, LATE_FKS

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "database"))
TODAY = datetime.date.today().isoformat()
RESERVED = set("""ACCESS ADD ALL ALTER AND ANY AS ASC AUDIT BETWEEN BY CHAR CHECK CLUSTER COLUMN COMMENT
COMPRESS CONNECT CREATE CURRENT DATE DECIMAL DEFAULT DELETE DESC DISTINCT DROP ELSE EXCLUSIVE EXISTS FILE
FLOAT FOR FROM GRANT GROUP HAVING IDENTIFIED IMMEDIATE IN INCREMENT INDEX INITIAL INSERT INTEGER INTERSECT
INTO IS LEVEL LIKE LOCK LONG MAXEXTENTS MINUS MLSLABEL MODE MODIFY NOAUDIT NOCOMPRESS NOT NOWAIT NULL NUMBER
OF OFFLINE ON ONLINE OPTION OR ORDER PCTFREE PRIOR PRIVILEGES PUBLIC RAW RENAME RESOURCE REVOKE ROW ROWID
ROWNUM ROWS SELECT SESSION SET SHARE SIZE SMALLINT START SUCCESSFUL SYNONYM SYSDATE TABLE THEN TO TRIGGER
UID UNION UNIQUE UPDATE USER VALIDATE VALUES VARCHAR VARCHAR2 VIEW WHENEVER WHERE WITH TYPE""".split())

def hdr(title, fname, run_as="HMS_APP"):
    return f"""/*
================================================================================
 Project   : Hospital Management System (HMS)
 Database  : Oracle 19c
 File      : {fname}
 Purpose   : {title}
 Run As    : {run_as}
 Generated : {TODAY}
================================================================================
*/
SET DEFINE OFF
"""

def seq_name(t):  return "SEQ_" + t["name"].replace("HMS_", "", 1)

def split_cols(body):
    """split column block by top-level commas"""
    out, depth, cur = [], 0, ""
    for ch in body:
        if ch == "(": depth += 1
        if ch == ")": depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += ch
    if cur.strip(): out.append(cur.strip())
    return [re.sub(r"\s+", " ", c) for c in out]

def col_name(c): return c.split()[0]

errors = []
fk_names = set()
all_tables = {}
created = set()
idx_lines = []
fk_idx_count = 0

def build_table(t):
    global fk_idx_count
    cols = split_cols(t["cols"])
    names = [col_name(c) for c in cols]
    for n in names:
        if n in RESERVED: errors.append(f"{t['name']}.{n} is reserved word")
        if len(n) > 30:   errors.append(f"{t['name']}.{n} > 30 chars")
    if len(t["name"]) > 30: errors.append(f"{t['name']} name > 30")
    if len(set(names)) != len(names): errors.append(f"{t['name']} duplicate column")
    # references
    for c in cols:
        for rt, rc in re.findall(r"REFERENCES (\w+)\((\w+)\)", c):
            if rt != t["name"] and rt not in created:
                errors.append(f"{t['name']}.{col_name(c)} -> {rt} not yet created (order!)")
            if rt == t["name"] and rc != t["pk"]:
                pass
            # FK index (skip if same single column already UNIQUE -> ORA-01408)
            if re.search(r"UNIQUE \(" + col_name(c) + r"\)", t["cons"]):
                continue
            fk_idx_count += 1
            iname = f"IX_{t['name'].replace('HMS_','')}_{col_name(c)}"
            iname = (iname[:30]).rstrip("_")
            idx_lines.append((t["name"], iname, col_name(c)))
    named = []
    for c in cols:
        mm = re.search(r"REFERENCES (\w+)\((\w+)\)", c)
        if mm:
            short = t['name'].replace('HMS_','')
            fkn = f"FK_{short}_{col_name(c)}"
            if len(fkn) > 30:
                fkn = "FK_" + "".join(w[:3] for w in short.split('_')) + "_" + col_name(c)
            fkn = fkn[:30].rstrip('_')
            if fkn in fk_names: fkn = fkn[:27] + f"_{len(fk_names)%100}"
            fk_names.add(fkn)
            c = c.replace("REFERENCES", f"CONSTRAINT {fkn} REFERENCES", 1)
        named.append(c)
    cols = named
    lines = [f"{t['pk']:<22} NUMBER DEFAULT {seq_name(t)}.NEXTVAL NOT NULL"]
    lines += [re.sub(r"^(\S+)\s+", lambda m: f"{m.group(1):<22} ", c) for c in cols]
    if t["active"]:
        lines.append(f"{'IS_ACTIVE':<22} CHAR(1) DEFAULT 'Y' NOT NULL CHECK (IS_ACTIVE IN ('Y','N'))")
    lines += [f"{'CREATED_BY':<22} VARCHAR2(100) DEFAULT NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER)",
              f"{'CREATED_DATE':<22} TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL",
              f"{'UPDATED_BY':<22} VARCHAR2(100)",
              f"{'UPDATED_DATE':<22} TIMESTAMP"]
    pkname = ("PK_" + t["name"].replace("HMS_", ""))[:30]
    lines.append(f"CONSTRAINT {pkname} PRIMARY KEY ({t['pk']}) USING INDEX TABLESPACE HMS_INDEX")
    if t["cons"]:
        for cn in [x.strip() for x in re.split(r",\s*\n\s*(?=CONSTRAINT)", t["cons"])]:
            lines.append(cn)
    lobs = [col_name(c) for c in cols if re.search(r"\b(BLOB|CLOB)\b", c)]
    sql = f"-- {'-'*76}\n-- {t['name']}" + (f"  : {t['comment']}" if t["comment"] else "") + f"\n-- {'-'*76}\n"
    sql += f"CREATE TABLE {t['name']} (\n    " + ",\n    ".join(lines) + "\n)\nTABLESPACE HMS_DATA"
    for l in lobs:
        sql += f"\nLOB ({l}) STORE AS SECUREFILE (TABLESPACE HMS_LOB)"
    sql += ";\n"
    if t["comment"]:
        c = t["comment"].replace("'", "''")
        sql += f"COMMENT ON TABLE {t['name']} IS '{c}';\n"
    sql += "\n"
    created.add(t["name"])
    return sql

# ---------------------------------------------------------------- tables
os.makedirs(f"{ROOT}/02_tables", exist_ok=True)
table_files = []
for no, fname, title, tables in MODULES:
    out = hdr(f"Tables - {title}", fname)
    out += f"\nPROMPT >>> Creating tables : {title}\n\n"
    for t in tables:
        all_tables[t["name"]] = t
        out += build_table(t)
    open(f"{ROOT}/02_tables/{fname}", "w").write(out)
    table_files.append((fname, title, [t["name"] for t in tables]))

# ---------------------------------------------------------------- sequences
os.makedirs(f"{ROOT}/01_sequences", exist_ok=True)
s = hdr("All sequences (one per table). START WITH value = &START_VALUE (PC-1 = 1, PC-2 = 1000001 etc.)",
        "create_all_sequences.sql")
s += """SET DEFINE ON
-- Development e 2 PC use korle ID clash na korar jonno start value alada rakhun.
-- Production e 1 use korben.
DEFINE START_VALUE = 1

PROMPT >>> Creating sequences ...
"""
for no, fname, title, tables in MODULES:
    s += f"\n-- {title}\n"
    for t in tables:
        cache = 1000 if t["name"] in ("HMS_AUDIT_TRAIL","HMS_PHARMA_TRANSACTION","HMS_LOGIN_HISTORY") else 20
        s += f"CREATE SEQUENCE {seq_name(t):<34} START WITH &START_VALUE INCREMENT BY 1 CACHE {cache} NOCYCLE;\n"
s += "\n-- Document number sequence (fallback)\nCREATE SEQUENCE SEQ_DOC_NO START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;\n\nSET DEFINE OFF\n"
open(f"{ROOT}/01_sequences/create_all_sequences.sql", "w").write(s)

# ---------------------------------------------------------------- indexes
os.makedirs(f"{ROOT}/03_indexes", exist_ok=True)
ix = hdr("Indexes : (A) Foreign-key indexes  (B) Search / report indexes", "create_all_indexes.sql")
ix += "\nPROMPT >>> Creating FK indexes ...\n-- (A) Oracle FK column e auto index kore na -> lock + slow join problem. Tai sob FK e index.\n"
seen = set()
for tbl, iname, col in idx_lines:
    base = iname; k = 1
    while iname in seen:
        k += 1; iname = base[:27] + f"_{k}"
    seen.add(iname)
    ix += f"CREATE INDEX {iname:<32} ON {tbl}({col}) TABLESPACE HMS_INDEX;\n"
ix += """
PROMPT >>> Creating search / report indexes ...
-- (B) Business search indexes
CREATE INDEX IX_PATIENT_PHONE        ON HMS_PATIENT(PHONE_PRIMARY) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PATIENT_NAME_UP      ON HMS_PATIENT(UPPER(FIRST_NAME||' '||LAST_NAME)) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PATIENT_NID          ON HMS_PATIENT(NID_NUMBER) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PATIENT_REG_DATE     ON HMS_PATIENT(REGISTRATION_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_OPD_VISIT_DATE_DOC   ON HMS_OPD_VISIT(VISIT_DATE, DOCTOR_ID) TABLESPACE HMS_INDEX;
CREATE INDEX IX_OPD_VISIT_STATUS     ON HMS_OPD_VISIT(VISIT_STATUS) TABLESPACE HMS_INDEX;
CREATE INDEX IX_APPT_DATE_DOC        ON HMS_APPOINTMENT(APPOINTMENT_DATE, DOCTOR_ID) TABLESPACE HMS_INDEX;
CREATE INDEX IX_IPD_ADM_STATUS       ON HMS_IPD_ADMISSION(ADMISSION_STATUS) TABLESPACE HMS_INDEX;
CREATE INDEX IX_IPD_ADM_DATE         ON HMS_IPD_ADMISSION(ADMISSION_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_BED_STATUS           ON HMS_BED(BED_STATUS) TABLESPACE HMS_INDEX;
CREATE INDEX IX_BILL_DATE            ON HMS_BILLING(BILL_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_BILL_STATUS          ON HMS_BILLING(BILL_STATUS) TABLESPACE HMS_INDEX;
CREATE INDEX IX_RECEIPT_DATE         ON HMS_PAYMENT_RECEIPT(RECEIPT_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_INV_ORDER_DATE       ON HMS_INVESTIGATION_ORDER(ORDER_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_INV_DTL_STATUS       ON HMS_INVESTIGATION_ORDER_DTL(ITEM_STATUS) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PH_STOCK_EXPIRY      ON HMS_PHARMA_STOCK(EXPIRY_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PH_SALE_DATE         ON HMS_PHARMA_SALE(SALE_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PH_ITEM_NAME_UP      ON HMS_PHARMA_ITEM(UPPER(ITEM_NAME)) TABLESPACE HMS_INDEX;
CREATE INDEX IX_PH_TXN_DATE          ON HMS_PHARMA_TRANSACTION(TXN_DATE) TABLESPACE HMS_INDEX;
CREATE INDEX IX_BLOOD_INV_GRP_STAT   ON HMS_BLOOD_INVENTORY(BLOOD_GROUP, UNIT_STATUS) TABLESPACE HMS_INDEX;
CREATE INDEX IX_AUDIT_TBL_REC        ON HMS_AUDIT_TRAIL(TABLE_NAME, RECORD_ID) TABLESPACE HMS_INDEX;
CREATE INDEX IX_AUDIT_TIME           ON HMS_AUDIT_TRAIL(ACTION_TIME) TABLESPACE HMS_INDEX;
CREATE INDEX IX_AUDIT_USER           ON HMS_AUDIT_TRAIL(ACTION_BY) TABLESPACE HMS_INDEX;
CREATE INDEX IX_ATTEND_DATE          ON HMS_ATTENDANCE(ATTENDANCE_DATE) TABLESPACE HMS_INDEX;
"""
open(f"{ROOT}/03_indexes/create_all_indexes.sql", "w").write(ix)

# ---------------------------------------------------------------- late FKs
fk = hdr("Late foreign keys (circular / forward reference)", "99_late_foreign_keys.sql")
fk += "\nPROMPT >>> Adding late foreign keys ...\n"
for tbl, cname, col, rt, rc in LATE_FKS:
    for x in (tbl, rt):
        if x not in all_tables: errors.append(f"late FK: {x} missing")
    fk += f"ALTER TABLE {tbl} ADD CONSTRAINT {cname} FOREIGN KEY ({col}) REFERENCES {rt}({rc});\n"
    ix_name = f"IX_{tbl.replace('HMS_','')}_{col}"[:30]
    fk += f"CREATE INDEX {ix_name} ON {tbl}({col}) TABLESPACE HMS_INDEX;\n"
open(f"{ROOT}/02_tables/99_late_foreign_keys.sql", "w").write(fk)

# ---------------------------------------------------------------- table list for other scripts
with open(os.path.join(os.path.dirname(__file__), "table_list.txt"), "w") as f:
    for no, fname, title, tables in MODULES:
        for t in tables: f.write(f"{t['name']}|{t['pk']}|{seq_name(t)}|{fname}\n")

n = sum(len(m[3]) for m in MODULES)
print(f"Tables: {n}, FK indexes: {fk_idx_count}, modules: {len(MODULES)}")
if errors:
    print("ERRORS:"); [print("  ", e) for e in errors]; sys.exit(1)
print("OK - no validation errors")

# ---------------------------------------------------------------- audit column triggers
os.makedirs(f"{ROOT}/06_triggers", exist_ok=True)
tr = hdr("UPDATED_BY / UPDATED_DATE auto set (every table, BEFORE UPDATE)", "TRG_AUDIT_COLUMNS.sql")
tr += "\nPROMPT >>> Creating audit-column triggers ...\n"
for no, fname, title, tables in MODULES:
    for t in tables:
        short = t["name"].replace("HMS_", "")
        tn = f"TRG_{short}_BU"
        if len(tn) > 30:
            tn = ("TRG_" + "".join(w[:4] for w in short.split("_")))[:27] + "_BU"
        tr += f"""CREATE OR REPLACE TRIGGER {tn}
BEFORE UPDATE ON {t['name']} FOR EACH ROW
BEGIN
    :NEW.UPDATED_BY   := NVL(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
    :NEW.UPDATED_DATE := SYSTIMESTAMP;
END;
/
"""
open(f"{ROOT}/06_triggers/TRG_AUDIT_COLUMNS.sql", "w").write(tr)
print("audit triggers written")
