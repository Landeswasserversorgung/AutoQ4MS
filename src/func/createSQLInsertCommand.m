% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function [sqlInsertCommand, columnsStr, valuesStr] = createSQLInsertCommand(Parameters, Tablename, Struct)
%CREATESQLINSERTCOMMAND  Build a parametrized INSERT statement string from a struct.
%   Uses table metadata in Parameters.database.tables.<Tablename> to validate the
%   provided struct fields and to cast/format values for SQL. Identifiers are quoted
%   to preserve case sensitivity; strings are sanitized and wrapped in single quotes.
%
%   Inputs:
%     Parameters - Struct containing:
%                  .database.schema  : schema name (string/char)
%                  .database.tables  : metadata map; field <Tablename> holds:
%                        .Names      : cellstr of column names
%                        .NotNull    : logical cell/array same length as Names
%                        .DataTypes  : cellstr SQL types, one per column
%     Tablename  - Name of the target table (string/char)
%     Struct     - Struct with field names matching column names
%
%   Outputs:
%     sqlInsertCommand - Complete SQL INSERT command as char
%     columnsStr       - Comma-separated quoted column identifiers
%     valuesStr        - Comma-separated value list (already SQL-formatted)
%
%   Example:
%     sql = createSQLInsertCommand(Parameters,'MyTable',struct('ID',1,'Name',"Alice"));
%

    % Get table metadata
    metatable = Parameters.database.tables.(Tablename);

    % Required columns (NotNull == true) must exist in the struct
    Names = metatable.Names(cell2mat(metatable.NotNull));  % values for these names must exist

    % Validate presence of required fields in the struct
    fields = fieldnames(Struct);
    areAllFieldsPresent = all(ismember(Names, fields));
    if ~areAllFieldsPresent
        error('The structure does not contain all the necessary values.');
    end

    % Check for extra fields not present in the table definition
    extraFields = setdiff(fields, metatable.Names);
    if ~isempty(extraFields)
        disp(extraFields);
        error('The structure contains values that are not stored in the database.');
    end

    % Initialize accumulators for columns and values
    columnsStr = '';
    valuesStr  = '';

    % Build value list in table order
    for i = 1:numel(metatable.Names)
        columnName = metatable.Names{i};

        % If the struct does not provide a value: insert NULL
        try
            Values = Struct.(columnName);
        catch
            columnsStr = [columnsStr, '"', columnName, '"', ', ']; %#ok<AGROW>
            valuesStr  = [valuesStr, 'NULL, '];                   %#ok<AGROW>
            continue; % no data for this column
        end

        % Numeric NaN is treated as NULL
        if isnumeric(Values)
            if isnan(Values)
                columnsStr = [columnsStr, '"', columnName, '"', ', ']; %#ok<AGROW>
                valuesStr  = [valuesStr, 'NULL, '];                   %#ok<AGROW>
                continue;
            end
        end

        % Cast/format by declared SQL data type
        switch metatable.DataTypes{i}
            case {'CHAR', 'VARCHAR'}
                % Sanitize: remove line breaks, carriage returns, non-printables, and single quotes
                cleanValues = strrep(char(Values), newline, ' ');
                cleanValues = strrep(cleanValues, char(13), ' ');
                cleanValues = regexprep(cleanValues, '[^\x20-\x7E]', ' ');
                cleanValues = strrep(cleanValues, '''', '');  % drop single quotes
                valueStr = ['''', cleanValues, ''''];         % wrap in single quotes

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
                    valueStr = ['''', char(datetime(Values, 'Format', 'yyyy-MM-dd HH:mm:ss')), ''''];
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

        % Append this column/value pair
        columnsStr = [columnsStr, '"', columnName, '"', ', ']; %#ok<AGROW>
        valuesStr  = [valuesStr, valueStr, ', '];              %#ok<AGROW>
    end

    % Trim trailing ", "
    columnsStr = columnsStr(1:end-2);
    valuesStr  = valuesStr(1:end-2);

    % Assemble final INSERT statement (identifiers quoted to preserve case)
    schemaName = strrep(Parameters.database.schema, newline, ''); % remove accidental newlines
    sqlInsertCommand = ['INSERT INTO "', schemaName, '"."', Tablename, '" (', columnsStr, ') VALUES (', valuesStr, ');'];

    % If the result is stored in a cell/string array, join to char
    if iscell(sqlInsertCommand) || isstring(sqlInsertCommand)
        sqlInsertCommand = strjoin(sqlInsertCommand, '');
    end

    % Also return valuesStr wrapped in parentheses for convenience
    valuesStr = [' (', valuesStr, ')'];
end
