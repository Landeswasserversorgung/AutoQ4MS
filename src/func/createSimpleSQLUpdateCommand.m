function sqlCmd = createSimpleSQLUpdateCommand(schemaName, tableName, columnName, value, whereConditions)
%CREATESIMPLESQLUPDATECOMMAND  Build a case-sensitive SQL UPDATE statement.
%   Constructs an SQL UPDATE command string using quoted identifiers for
%   schema, table, and column names to preserve case sensitivity.
%
%   Inputs:
%     schemaName      - e.g., 'dbo'
%     tableName       - e.g., 'ISValue'
%     columnName      - e.g., 'intensity'
%     value           - New value (numeric, string, or char)
%     whereConditions - Cell array of key/value pairs:
%                       e.g., {'ID', 1; 'SampleName', 'A1'}
%
%   Output:
%     sqlCmd - SQL UPDATE statement as a string
%
%   Example:
%     sqlCmd = createSimpleSQLUpdateCommand('dbo','ISValue','intensity',42, ...
%               {'ID',1;'SampleName','A1'});
%

    % Format SET value
    if isnan(value)
        valStr = 'NULL';
    elseif isnumeric(value)
        valStr = num2str(value);
    elseif ischar(value) || isstring(value)
        valStr = ['''' char(value) ''''];
    elseif isempty(value)
        valStr = 'NULL';
    else
        error('Unsupported value type.');
    end

    % Format WHERE conditions
    whereStrs = cell(size(whereConditions, 1), 1);
    for i = 1:size(whereConditions, 1)
        col = whereConditions{i, 1};
        condVal = whereConditions{i, 2};

        colQuoted = sprintf('"%s"', col);  % Always case-sensitive

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

    % Build the final SQL command with quoted identifiers
    sqlCmd = sprintf('UPDATE "%s"."%s" SET "%s" = %s WHERE %s;', ...
                     schemaName, tableName, columnName, valStr, whereClause);
end




