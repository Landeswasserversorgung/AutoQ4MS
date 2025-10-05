function sqlCmd = createSimpleSQLUpdateCommand(schemaName, tableName, columnName, value, whereConditions)

% Erstellt einen SQL UPDATE-Befehl mit durchgängig case-sensitiven Namen
%
% Inputs:
%   schemaName       - z. B. 'dbo'
%   tableName        - z. B. 'ISValue'
%   columnName       - z. B. 'intensity'
%   value            - Neuer Wert (numeric, string, char)
%   whereConditions  - Cell-Array: z. B. {'ID', 1; 'SampleName', 'A1'}
%
% Output:
%   sqlCmd           - SQL-Update-Statement (String)

    % Format SET-Wert
    if isnumeric(value)
        valStr = num2str(value);
    elseif ischar(value) || isstring(value)
        valStr = ['''' char(value) ''''];
    elseif isempty(value)
        valStr = 'NULL';
    else
        error('Unsupported value type.');
    end

    % Format WHERE-Bedingungen
    whereStrs = cell(size(whereConditions, 1), 1);
    for i = 1:size(whereConditions, 1)
        col = whereConditions{i, 1};
        condVal = whereConditions{i, 2};

        colQuoted = sprintf('"%s"', col);  % Immer case-sensitive

        if isnumeric(condVal)
            condStr = sprintf('%s = %g', colQuoted, condVal);
        elseif ischar(condVal) || isstring(condVal)
            condStr = sprintf('%s = ''%s''', colQuoted, char(condVal));
        elseif isempty(condVal)
            condStr = sprintf('%s IS NULL', colQuoted);
        else
            error('Unsupported WHERE condition value type.');
        end

        whereStrs{i} = condStr;
    end

    whereClause = strjoin(whereStrs, ' AND ');

    % SQL-Zeile mit durchgängig gequoteten Namen
    sqlCmd = sprintf('UPDATE "%s"."%s" SET "%s" = %s WHERE %s;', ...
                     schemaName, tableName, columnName, valStr, whereClause);
end



