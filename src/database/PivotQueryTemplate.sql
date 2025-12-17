DO $$
DECLARE
    komponenten TEXT;
BEGIN
    -- Dynamically build the pivot column list for all distinct IDs.
    -- Each ID becomes a column using: MAX(CASE WHEN "ID"=... THEN "EXTRACT" END) AS "<ID>"
    SELECT string_agg(
        DISTINCT format(
            'MAX(CASE WHEN "ID" = ''%s'' THEN "EXTRACT" ELSE NULL END) AS "%s"',
            "ID", "ID"
        ),
        ', '
    )
    INTO komponenten
    FROM "SCHEMA"."TABLE_NAME"
    WHERE "ID" IS NOT NULL;

    -- Create a temporary pivot table containing datetime_aq plus one column per ID.
    -- The placeholders START_DATE/END_DATE/EXTRACT/TABLE_NAME/SCHEMA/*Condition are replaced by MATLAB.
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

-- Export the temporary pivot table to a CSV file (server-side via psql \copy).
\copy temp_final_ISValue TO 'OUTPUT_PATH' CSV HEADER;

-- Optional debug output:
-- SELECT * FROM temp_final_ISValue;
