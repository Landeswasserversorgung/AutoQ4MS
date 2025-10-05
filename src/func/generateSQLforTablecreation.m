function [SQLCommand] = generateSQLforTablecreation(tableMeta, tableName,schemaName)
%% This Function generates for a table in the format see below a SQL Command to create the Table in postgeSQL.
% Linus Straehle 2024-05-16
%
% Names = {'SampleID', 'polarity', 'type', 'datetime', 'batch', 'ISCheck', 'Donau outflow', 'concentrationLevel_ngL'}';
% DataTypes = {'VARCHAR', 'CHAR', 'VARCHAR', 'timestamp without time zone', 'VARCHAR', 'BOOLEAN', 'FLOAT', 'FLOAT'}';
% Lengths = {[], 1, 10, [], [], [], [], []}';  % [] means no lenth 
% Scales = {[], [], [], [], [], [], [], []}';  % [] means no scale
% NotNull = {true, true, true, true, false, false, false, false}';
% PrimaryKey = {true, false, false, false, false, false, false, false}';
%
% tableMeta = table(Names, DataTypes, Lengths, Scales, NotNull, PrimaryKey);

    SQLCommand = sprintf('CREATE TABLE IF NOT EXISTS "%s"."%s" (',schemaName, tableName);
    
    for i = 1:height(tableMeta)
        columnDef = sprintf('"%s" %s', tableMeta.Names{i}, tableMeta.DataTypes{i});
        
        if ~isempty(tableMeta.Lengths{i})
            columnDef = sprintf('%s(%d)', columnDef, tableMeta.Lengths{i});
        end
        
        if ~isempty(tableMeta.Scales{i})
            columnDef = sprintf('%s(%d)', columnDef, tableMeta.Scales{i});
        end
        
        if tableMeta.NotNull{i}
            columnDef = sprintf('%s NOT NULL', columnDef);
        end
        
        if tableMeta.PrimaryKey{i}
            columnDef = sprintf('%s PRIMARY KEY', columnDef);
        end
        
        if i < height(tableMeta)
            columnDef = sprintf('%s,', columnDef);
        end
        
        SQLCommand = sprintf('%s %s', SQLCommand, columnDef);
    end
    
    SQLCommand = sprintf('%s );', SQLCommand);


end

