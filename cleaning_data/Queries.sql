-- Count total rows
SELECT COUNT(*) AS total_rows FROM crimes_data;

-- Clean invalid victim age
UPDATE crimes_data
SET VICT_AGE = NULL
WHERE VICT_AGE < 0 OR VICT_AGE > 120;


-- Normalize victim sex values
UPDATE crimes_data
SET VICT_SEX = UPPER(TRIM(VICT_SEX))
WHERE VICT_SEX IS NOT NULL;

-- Standardize victim sex categories
UPDATE crimes_data
SET VICT_SEX = CASE
    WHEN VICT_SEX IS NULL OR VICT_SEX = '' THEN 'Unknown'
    WHEN VICT_SEX IN ('M','MALE','M.', 'MAN','BOY') THEN 'M'
    WHEN VICT_SEX IN ('F','FEMALE','F.', 'WOMAN','GIRL') THEN 'F'
    WHEN VICT_SEX IN ('X','U','UNK','UNKNOWN','N/A','NA','-','*','?') THEN 'Unknown'
    ELSE VICT_SEX
END;

-- Normalize victim descent values
UPDATE crimes_data
SET VICT_DESCENT = UPPER(TRIM(VICT_DESCENT))
WHERE VICT_DESCENT IS NOT NULL;

-- Standardize victim descent categories
UPDATE crimes_data
SET VICT_DESCENT = CASE
    WHEN VICT_DESCENT IS NULL OR VICT_DESCENT = '' OR LENGTH(VICT_DESCENT) > 1 THEN 'Unknown'
    ELSE VICT_DESCENT
END;

-- Trim area names
UPDATE crimes_data
SET AREA_NAME = TRIM(AREA_NAME)
WHERE AREA_NAME IS NOT NULL;

-- Standardize area names
UPDATE crimes_data
SET AREA_NAME = CASE
    WHEN AREA_NAME IS NULL OR AREA_NAME = '' THEN 'Unknown'
    ELSE UPPER(SUBSTR(AREA_NAME, 1, 1)) || LOWER(SUBSTR(AREA_NAME, 2))
END;

-- Trim weapon descriptions
UPDATE crimes_data
SET WEAPON_DESC = TRIM(WEAPON_DESC)
WHERE WEAPON_DESC IS NOT NULL;

-- Standardize weapon descriptions
UPDATE crimes_data
SET WEAPON_DESC = CASE
    WHEN WEAPON_DESC IS NULL OR WEAPON_DESC = '' THEN 'Unknown'
    ELSE WEAPON_DESC
END;

-- Trim location values
UPDATE crimes_data
SET LOCATION = TRIM(LOCATION)
WHERE LOCATION IS NOT NULL;

-- Replace missing locations with 'Unknown'
UPDATE crimes_data
SET LOCATION = CASE
    WHEN LOCATION IS NULL OR LOCATION = '' THEN 'Unknown'
    ELSE LOCATION
END;

-- Collapse multiple spaces in location
UPDATE crimes_data
SET LOCATION = REPLACE(LOCATION, '  ', ' ')
WHERE LOCATION LIKE '%  %';

-- Format location capitalization
UPDATE crimes_data
SET LOCATION = UPPER(SUBSTR(LOCATION, 1, 1)) || LOWER(SUBSTR(LOCATION, 2))
WHERE LOCATION NOT IN ('Unknown');

-- Clean invalid or missing DATE_OCC
UPDATE crimes_data
SET DATE_OCC = NULL
WHERE DATE_OCC IS NULL;


-- Add a cleaned date column (only if not exists)
ALTER TABLE crimes_data ADD COLUMN IF NOT EXISTS DATE_OCC_CLEAN DATE;

-- Fill cleaned date column
UPDATE crimes_data
SET DATE_OCC_CLEAN = DATE(DATE_OCC)
WHERE DATE_OCC IS NOT NULL;

-- Remove duplicates by recreating table
CREATE TABLE temp_crimes_data AS
SELECT DISTINCT * FROM crimes_data;

-- Drop old table
DROP TABLE crimes_data;

-- Rename temp table to crimes_data
ALTER TABLE temp_crimes_data RENAME TO crimes_data;

-- Final quality checks
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN VICT_AGE = NULL THEN 1 ELSE 0 END) AS unknown_age,
    SUM(CASE WHEN VICT_SEX = 'Unknown' THEN 1 ELSE 0 END) AS unknown_sex,
    SUM(CASE WHEN VICT_DESCENT = 'Unknown' THEN 1 ELSE 0 END) AS unknown_descent,
    SUM(CASE WHEN AREA_NAME = 'Unknown' THEN 1 ELSE 0 END) AS unknown_area,
    SUM(CASE WHEN WEAPON_DESC = 'Unknown' THEN 1 ELSE 0 END) AS unknown_weapon,
    SUM(CASE WHEN LOCATION = 'Unknown' THEN 1 ELSE 0 END) AS unknown_location,
    SUM(CASE WHEN DATE_OCC IS NULL THEN 1 ELSE 0 END) AS null_dates
FROM crimes_data;

-- Count by victim sex
SELECT VICT_SEX, COUNT(*) FROM crimes_data GROUP BY VICT_SEX;

-- Count by victim descent
SELECT VICT_DESCENT, COUNT(*) FROM crimes_data GROUP BY VICT_DESCENT;

-- Count by area
SELECT AREA_NAME, COUNT(*) FROM crimes_data GROUP BY AREA_NAME;

-- Select cleaned columns
SELECT 
    DR_NO,
    DATE_OCC_CLEAN AS DATE_OCC,
    TIME_OCC,
    AREA_NAME,
    VICT_AGE,
    VICT_SEX,
    VICT_DESCENT,
    WEAPON_DESC,
    LOCATION
FROM crimes_data;


