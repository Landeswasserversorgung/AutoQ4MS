function [Table,outputPath] = SQLRequest(startDate,endDate, polarity,extract,Table,ISCheck,Type, Parameters)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% Parameter definieren
% Setting options and examples
% startDate = '2024-06-01 00:00:00';
% endDate = '2024-07-03 23:59:59';
% polarity = '+'; '+' or '-' or ''for both modes
% extract = 'intensity'; %
% Table = 'ISValue'; % 'ComponentValue' or 'ISValue'
% ISCheck = 'true'; % 'true' or 'false' or '' for both

% Paths
outputPath = strjoin([Parameters.path.program, '\src\database\sqlQueryOutput.csv'],"");
templatePath = strjoin([Parameters.path.program,'\src\database\PivotQueryTemplate.sql'],"");

% read Template 
fileIDTemp = fopen(templatePath, 'r');
sqlTemplate = fread(fileIDTemp, '*char')';
fclose(fileIDTemp);

% Forming a string for an SQL condition if the variables are defined
if numel(polarity)
    polarityCondition = sprintf('AND sm."polarity" = ''''%s''''', polarity);
else
    % both are returned
    polarityCondition = '';    
end
if numel(ISCheck)
    ISCheckCondition = sprintf('AND sm."ISCheck" = ''''%s''''', ISCheck);
else
    % both are returend
    ISCheckCondition = '';   
end
if numel(Type)
    TypeCondition = sprintf('AND sm."type" = ''''%s''''', Type);
else
    % both are returend
    TypeCondition = '';   
end

% Do settings in the query
sqlQuery = strrep(sqlTemplate, 'START_DATE', startDate);
sqlQuery = strrep(sqlQuery, 'END_DATE', endDate);
sqlQuery = strrep(sqlQuery, 'polarityCondition', polarityCondition);
sqlQuery = strrep(sqlQuery, 'EXTRACT', extract);
sqlQuery = strrep(sqlQuery, 'TABLE_NAME', Table);
sqlQuery = strrep(sqlQuery, 'OUTPUT_PATH', outputPath);
sqlQuery = strrep(sqlQuery, 'ISCheckCondition', ISCheckCondition);
sqlQuery = strrep(sqlQuery, 'TypeCondition', TypeCondition);
sqlQuery = strrep(sqlQuery, 'SCHEMA', Parameters.database.schema);



% Aktualisierte Abfrage in eine neue Datei schreiben

queryPath = newsqlfile(Parameters);
fileID = fopen(queryPath, 'w');
fwrite(fileID, convertUmlauts(sqlQuery));
fclose(fileID);


% Run SQL Command 
setenv('PGPASSWORD', Parameters.database.password);
command = sprintf('"%s" -h "%s" -p "%s" -U "%s" -d "%s" -f "%s"', ...
    Parameters.path.psqlExe, Parameters.database.host, Parameters.database.port, ...
    Parameters.database.username, Parameters.database.dbname, queryPath);
[status, cmdout] = system(command);

%disp(cmdout);
cmdout = regexprep(cmdout, '[^\x20-\x7E]', '');

if ~contains(cmdout,'DOCOPY')
    %disp(cmdout);
    error('error in SQL Query');
end
delete(queryPath);

Table = readtable(outputPath);

end

