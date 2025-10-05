DO $$
DECLARE
    komponenten TEXT;
BEGIN
    -- Dynamische Generierung der Komponentenliste
    SELECT string_agg(DISTINCT format(
        'MAX(CASE WHEN "ID" = ''%s'' THEN "EXTRACT" ELSE NULL END) AS "%s"',
        "ID", "ID"), ', ')
    INTO komponenten
    FROM "SCHEMA"."TABLE_NAME"
    WHERE "ID" IS NOT NULL;

    -- Dynamische Generierung der Pivot-Abfrage
    EXECUTE format(
        'CREATE TEMP TABLE temp_final_ISValue AS
        SELECT datetime_aq, %s
        FROM "SCHEMA"."TABLE_NAME" cv
        JOIN "SCHEMA"."SampleMaster" sm ON cv."SampID" = sm."SampleID"
        WHERE 
        sm.datetime_aq BETWEEN ''START_DATE'' AND ''END_DATE''
        polarityCondition
        TypeCondition
        ISCheckCondition
        
        GROUP BY datetime_aq
        ORDER BY datetime_aq',
        komponenten
    );

END $$;

-- Exportieren der temporaeren Tabelle in eine CSV-Datei
\copy temp_final_ISValue TO 'OUTPUT_PATH' CSV HEADER;

 --SELECT * FROM temp_final_ISValue;  -- Zum Prüfen der Ergebnisse