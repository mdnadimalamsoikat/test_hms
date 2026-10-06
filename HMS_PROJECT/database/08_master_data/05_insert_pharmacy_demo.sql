/*
================================================================================
 File    : database/08_master_data/05_insert_pharmacy_demo.sql
 Run As  : HMS_APP     (SQL Workshop > SQL Scripts)   — re-runnable (NOT EXISTS)
 Purpose : Demo generics, manufacturers, 20 medicines (ITEM_CODE trigger theke MED-0000x)
 Pre-req : TRG_AUTO_CODES.sql (TRG_PHARMA_ITEM_CODE_BI) + category seed (02_insert_lookup_data.sql)
================================================================================
*/
SET DEFINE OFF

INSERT INTO HMS_PHARMA_GENERIC (GENERIC_NAME)
SELECT v.V_NAME FROM (
  SELECT 'Paracetamol' V_NAME FROM DUAL UNION ALL SELECT 'Omeprazole' FROM DUAL UNION ALL
  SELECT 'Esomeprazole' FROM DUAL UNION ALL SELECT 'Amoxicillin' FROM DUAL UNION ALL
  SELECT 'Azithromycin' FROM DUAL UNION ALL SELECT 'Ciprofloxacin' FROM DUAL UNION ALL
  SELECT 'Metronidazole' FROM DUAL UNION ALL SELECT 'Metformin' FROM DUAL UNION ALL
  SELECT 'Amlodipine' FROM DUAL UNION ALL SELECT 'Atorvastatin' FROM DUAL UNION ALL
  SELECT 'Salbutamol' FROM DUAL UNION ALL SELECT 'Cetirizine' FROM DUAL UNION ALL
  SELECT 'Diclofenac' FROM DUAL UNION ALL SELECT 'Ondansetron' FROM DUAL UNION ALL
  SELECT 'Ceftriaxone' FROM DUAL UNION ALL SELECT 'Sodium Chloride' FROM DUAL UNION ALL
  SELECT 'Dextrose' FROM DUAL UNION ALL SELECT 'Clotrimazole' FROM DUAL) v
 WHERE NOT EXISTS (SELECT 1 FROM HMS_PHARMA_GENERIC t WHERE t.GENERIC_NAME = v.V_NAME);

INSERT INTO HMS_PHARMA_MANUFACTURER (MANUFACTURER_NAME)
SELECT v.V_NAME FROM (
  SELECT 'Square Pharmaceuticals' V_NAME FROM DUAL UNION ALL SELECT 'Beximco Pharmaceuticals' FROM DUAL UNION ALL
  SELECT 'Incepta Pharmaceuticals' FROM DUAL UNION ALL SELECT 'Renata Limited' FROM DUAL UNION ALL
  SELECT 'ACI Limited' FROM DUAL) v
 WHERE NOT EXISTS (SELECT 1 FROM HMS_PHARMA_MANUFACTURER t WHERE t.MANUFACTURER_NAME = v.V_NAME);

INSERT INTO HMS_PHARMA_ITEM (ITEM_NAME, GENERIC_ID, PH_CATEGORY_ID, MANUFACTURER_ID, STRENGTH, DOSAGE_FORM, UNIT_OF_MEASURE,
                             PURCHASE_PRICE, MRP, REORDER_LEVEL, IS_ANTIBIOTIC, REQUIRES_PRESCRIPTION)
SELECT v.V_ITEM, g.GENERIC_ID, c.PH_CATEGORY_ID, m.MANUFACTURER_ID, v.V_STRENGTH, v.V_FORM, v.V_UOM,
       v.V_BUY, v.V_MRP, v.V_REORDER, v.V_ANTIB, v.V_RX
  FROM (SELECT 'Napa' V_ITEM, 'Paracetamol' V_GEN, 'Tablet' V_CAT, 'Square Pharmaceuticals' V_MFR, '500 mg' V_STRENGTH, 'Tablet' V_FORM, 'Pcs' V_UOM, 0.9 V_BUY, 1.2 V_MRP, 500 V_REORDER, 'N' V_ANTIB, 'N' V_RX FROM DUAL UNION ALL
        SELECT 'Napa Syrup', 'Paracetamol',   'Syrup',            'Square Pharmaceuticals',  '120 mg/5 ml', 'Syrup',     'Bottle', 30, 40,  50,  'N', 'N' FROM DUAL UNION ALL
        SELECT 'Seclo',      'Omeprazole',    'Capsule',          'Square Pharmaceuticals',  '20 mg',       'Capsule',   'Pcs',    4.5, 6,  300, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Maxpro',     'Esomeprazole',  'Tablet',           'Renata Limited',          '20 mg',       'Tablet',    'Pcs',    5, 7,    300, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Moxacil',    'Amoxicillin',   'Capsule',          'Square Pharmaceuticals',  '500 mg',      'Capsule',   'Pcs',    6, 8,    300, 'Y', 'Y' FROM DUAL UNION ALL
        SELECT 'Zimax',      'Azithromycin',  'Tablet',           'Square Pharmaceuticals',  '500 mg',      'Tablet',    'Pcs',    28, 35,  100, 'Y', 'Y' FROM DUAL UNION ALL
        SELECT 'Ciprocin',   'Ciprofloxacin', 'Tablet',           'Square Pharmaceuticals',  '500 mg',      'Tablet',    'Pcs',    9, 12,   200, 'Y', 'Y' FROM DUAL UNION ALL
        SELECT 'Filmet',     'Metronidazole', 'Tablet',           'Beximco Pharmaceuticals', '400 mg',      'Tablet',    'Pcs',    1.8, 2.5, 300, 'Y', 'Y' FROM DUAL UNION ALL
        SELECT 'Glucomin',   'Metformin',     'Tablet',           'Incepta Pharmaceuticals', '500 mg',      'Tablet',    'Pcs',    1.8, 2.5, 500, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Amlodin',    'Amlodipine',    'Tablet',           'Square Pharmaceuticals',  '5 mg',        'Tablet',    'Pcs',    2.2, 3,   300, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Atova',      'Atorvastatin',  'Tablet',           'Incepta Pharmaceuticals', '10 mg',       'Tablet',    'Pcs',    6, 8,    200, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Brodil',     'Salbutamol',    'Syrup',            'Renata Limited',          '2 mg/5 ml',   'Syrup',     'Bottle', 35, 45,  50,  'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Alatrol',    'Cetirizine',    'Tablet',           'Square Pharmaceuticals',  '10 mg',       'Tablet',    'Pcs',    1.5, 2,   300, 'N', 'N' FROM DUAL UNION ALL
        SELECT 'Clofenac',   'Diclofenac',    'Tablet',           'Square Pharmaceuticals',  '50 mg',       'Tablet',    'Pcs',    2.5, 3.5, 300, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Emistat',    'Ondansetron',   'Tablet',           'Square Pharmaceuticals',  '4 mg',        'Tablet',    'Pcs',    5, 7,    200, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Ceftron',    'Ceftriaxone',   'Injection',        'Square Pharmaceuticals',  '1 gm',        'Injection', 'Vial',   70, 95,  50,  'Y', 'Y' FROM DUAL UNION ALL
        SELECT 'Normal Saline', 'Sodium Chloride', 'IV Fluid',    'Beximco Pharmaceuticals', '0.9% 500 ml', 'Infusion',  'Bag',    55, 70,  100, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Dextrose 5%',   'Dextrose',    'IV Fluid',        'Beximco Pharmaceuticals', '5% 500 ml',   'Infusion',  'Bag',    55, 70,  100, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Clofenac Inj',  'Diclofenac',  'Injection',       'Square Pharmaceuticals',  '75 mg/3 ml',  'Injection', 'Amp',    15, 20,  100, 'N', 'Y' FROM DUAL UNION ALL
        SELECT 'Clotrim',       'Clotrimazole','Ointment / Cream','ACI Limited',             '1% 10 g',     'Ointment',  'Tube',   40, 55,  50,  'N', 'N' FROM DUAL) v
  JOIN HMS_PHARMA_GENERIC      g ON g.GENERIC_NAME      = v.V_GEN
  JOIN HMS_PHARMA_CATEGORY     c ON c.CATEGORY_NAME     = v.V_CAT
  JOIN HMS_PHARMA_MANUFACTURER m ON m.MANUFACTURER_NAME = v.V_MFR
 WHERE NOT EXISTS (SELECT 1 FROM HMS_PHARMA_ITEM t WHERE t.ITEM_NAME = v.V_ITEM AND NVL(t.STRENGTH,'-') = v.V_STRENGTH);

COMMIT;

SELECT (SELECT COUNT(*) FROM HMS_PHARMA_GENERIC)      generics,
       (SELECT COUNT(*) FROM HMS_PHARMA_MANUFACTURER) manufacturers,
       (SELECT COUNT(*) FROM HMS_PHARMA_ITEM)         items,
       (SELECT MIN(ITEM_CODE) FROM HMS_PHARMA_ITEM)   first_code
  FROM DUAL;
