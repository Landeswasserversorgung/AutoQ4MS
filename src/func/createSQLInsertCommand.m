function [sqlInsertCommand,columnsStr,valuesStr] = createSQLInsertCommand(Parameters, Tablename, Struct)

% Metadaten der Tabelle abrufen
metatable = Parameters.database.tables.(Tablename);
Names = metatable.Names(cell2mat(metatable.NotNull)); % Werte für diese Namen müssen in der Struktur vorhanden sein

% Überprüfen, ob alle erforderlichen Namen als Felder in der Struktur vorhanden sind
fields = fieldnames(Struct);
areAllFieldsPresent = all(ismember(Names, fields));

if ~areAllFieldsPresent
   error("The structure does not contain all the necessary values.");
end

% Überprüfen, ob in der Struktur Felder vorhanden sind, die nicht in der Tabelle sind
extraFields = setdiff(fields, metatable.Names);

if ~isempty(extraFields)
    disp(extraFields);
    error('The structure contains values that are not stored in the database.');
end

% Initialisieren von Zeichenketten für Spalten und Werte
columnsStr = '';
valuesStr = '';



for i = 1:numel(metatable.Names)
    columnName = metatable.Names{i};
    try
        Values = Struct.(columnName);
    catch
        columnsStr = [columnsStr, '"', columnName,'"', ', '];
        valuesStr = [valuesStr, 'NULL, '];
        continue; % keine Daten für die Variable
    end
    
    if isnumeric(Values) 
        if isnan(Values)
            columnsStr = [columnsStr, '"', columnName,'"', ', '];
            valuesStr = [valuesStr, 'NULL, '];
            continue; % keine Daten für die Variable
        end
    end
    
    switch metatable.DataTypes{i}
        case {'CHAR', 'VARCHAR'}
                % Remove line breaks and replace with spaces
                cleanValues = strrep(char(Values), newline, ' ');
                cleanValues = strrep(cleanValues, char(13), ' ');  % Removes carriage return (\r)
                % Replace all non-printable characters with spaces
                cleanValues = regexprep(cleanValues, '[^\x20-\x7E]', ' ');
                cleanValues = strrep(cleanValues, '''', '');
                valueStr = ['''', cleanValues, ''''];% Enclose strings in single inverted commas
        case {'FLOAT', 'DOUBLE PRECISION'}
            valueStr = num2str(Values);
        case {'INT', 'INTEGER', 'SMALLINT'}
            valueStr = num2str(int32(Values));
        case 'BOOLEAN'
            if islogical(Values)
                 if Values 
                    valueStr = 'TRUE';
                else
                    valueStr = 'FALSE';
                 end
            else
                if strcmp(Values, 'true') || strcmp(Values, '1') 
                    valueStr = 'TRUE';
                else
                    valueStr = 'FALSE';
                end
            end
        case 'timestamp without time zone'
                if ismissing(Values) || isnat(Values)
                    valueStr = 'NULL';
                else
                    valueStr = ['''' char(datetime(Values, 'Format', 'yyyy-MM-dd HH:mm:ss')) ''''];
                end
        case 'DOUBLE PRECISION[]'
            valueStr = ['ARRAY[', strjoin(arrayfun(@num2str, Values, 'UniformOutput', false), ','), ']'];
        case 'INT[]'
            valueStr = ['ARRAY[', strjoin(arrayfun(@(x) num2str(int32(x)), Values, 'UniformOutput', false), ','), ']'];
        case 'FLOAT[]'
            valueStr = ['ARRAY[', strjoin(arrayfun(@num2str, Values, 'UniformOutput', false), ','), ']'];
        otherwise
            disp(metatable.DataTypes{i});
            error('The data type is not supported.');
    end
    
    columnsStr = [columnsStr, '"', columnName,'"', ', '];
    valuesStr = [valuesStr, valueStr, ', '];
end

% Entfernen des letzten Kommas und Leerzeichens
columnsStr = columnsStr(1:end-2);
valuesStr = valuesStr(1:end-2);

% SQL-Insert-Befehl zusammenstellen
sqlInsertCommand = ['INSERT INTO "', strrep(Parameters.database.schema, newline, '') ,'"."', Tablename, '" (', columnsStr, ') VALUES (', valuesStr, ');'];

if iscell(sqlInsertCommand) || isstring(sqlInsertCommand)
    % Mehrere Teile? Dann zusammenfügen
    sqlInsertCommand = strjoin(sqlInsertCommand, '');
end
valuesStr = [' (', valuesStr, ')'];
end


