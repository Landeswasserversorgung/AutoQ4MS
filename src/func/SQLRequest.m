function [Table, outputPath] = SQLRequest(startDate, endDate, polarity, extract, Table, ISCheck, Type, Parameters)
%SQLREQUEST  Execute a templated SQL pivot query via psql and return the result as a table.
%
%   [Table, outputPath] = SQLRequest(startDate, endDate, polarity, extract, Table, ISCheck, Type, Parameters)
%   Loads an SQL template, replaces placeholders (date range, table name, extract field,
%   optional filters), writes the resulting SQL into a temporary .sql file, executes it
%   using the psql CLI, and reads the produced CSV output into a MATLAB table.
%
%   Inputs:
%     startDate  - Start timestamp string, e.g. '2024-06-01 00:00:00'
%     endDate    - End timestamp string,   e.g. '2024-07-03 23:59:59'
%     polarity   - '+' or '-' or '' for both modes
%     extract    - Extract key used by the SQL template (e.g. 'foundRT', 'massaccuracy', 'normIntensities', ...)
%     Table      - Table name (e.g. 'ISValue' or 'ComponentValue')
%     ISCheck    - 'true' / 'false' or '' for both
%     Type       - Sample type string or '' for all
%     Parameters - Project parameters struct (database credentials, paths, schema)
%
%   Outputs:
%     Table      - MATLAB table read from the query CSV output
%     outputPath - Full path to the generated CSV output file
%
   %% Paths
       uuid = char(java.util.UUID.randomUUID);
    
    outputPath = fullfile( ...
        Parameters.path.program, ...
        'src', 'database', ...
        ['sqlQueryOutput_' uuid '.csv'] ...
    );
    
    templatePath = strjoin([Parameters.path.program, '\src\database\PivotQueryTemplate.sql'], "");

    %% Read template
    fileIDTemp  = fopen(templatePath, 'r');
    sqlTemplate = fread(fileIDTemp, '*char')';
    fclose(fileIDTemp);

    %% Build optional SQL conditions
    if numel(polarity)
        polarityCondition = sprintf('AND sm."polarity" = ''''%s''''', polarity);
    else
        polarityCondition = '';
    end

    if numel(ISCheck)
        ISCheckCondition = sprintf('AND sm."ISCheck" = ''''%s''''', ISCheck);
    else
        ISCheckCondition = '';
    end

    if numel(Type)
        TypeCondition = sprintf('AND sm."type" = ''''%s''''', Type);
    else
        TypeCondition = '';
    end

    %% Apply settings to the SQL template
    sqlQuery = strrep(sqlTemplate, 'START_DATE', startDate);
    sqlQuery = strrep(sqlQuery, 'END_DATE', endDate);
    sqlQuery = strrep(sqlQuery, 'polarityCondition', polarityCondition);
    sqlQuery = strrep(sqlQuery, 'EXTRACT', extract);
    sqlQuery = strrep(sqlQuery, 'TABLE_NAME', Table);
    sqlQuery = strrep(sqlQuery, 'OUTPUT_PATH', outputPath);
    sqlQuery = strrep(sqlQuery, 'ISCheckCondition', ISCheckCondition);
    sqlQuery = strrep(sqlQuery, 'TypeCondition', TypeCondition);
    sqlQuery = strrep(sqlQuery, 'SCHEMA', Parameters.database.schema);

    %% Write updated query into a new SQL file
    queryPath = newsqlfile(Parameters);
    fileID = fopen(queryPath, 'w');
    fwrite(fileID, convertUmlauts(sqlQuery));
    fclose(fileID);

    %% Execute SQL command via psql
    setenv('PGPASSWORD', Parameters.database.password);
    command = sprintf('"%s" -h "%s" -p "%s" -U "%s" -d "%s" -f "%s"', ...
        Parameters.path.psqlExe, Parameters.database.host, Parameters.database.port, ...
        Parameters.database.username, Parameters.database.dbname, queryPath);

    [status, cmdout] = system(command); %#ok<ASGLU>

    % Sanitize output to printable ASCII
    cmdout = regexprep(cmdout, '[^\x20-\x7E]', '');

    % Validate psql output
    if ~contains(cmdout, 'DOCOPY')
        error('Error in SQL query.');
    end

    % Cleanup temp query file
    delete(queryPath);

    %% Read CSV output as table
    Table = readtable(outputPath);
end


