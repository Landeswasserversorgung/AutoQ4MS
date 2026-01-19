% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function SQLCommand = generateSQLforTablecreation(tableMeta, tableName, schemaName)
%GENERATESQLFORTABLECREATION  Generate a SQL CREATE TABLE statement for PostgreSQL.
%   SQLCommand = generateSQLforTablecreation(tableMeta, tableName, schemaName)
%
%   Builds a PostgreSQL-compatible CREATE TABLE statement based on metadata
%   provided in a MATLAB table.
%
%   Expected tableMeta columns:
%     Names       - Column names (cell array of char/string)
%     DataTypes   - SQL data types (e.g. 'VARCHAR', 'FLOAT', 'BOOLEAN', ...)
%     Lengths     - Optional length specifier ([], or numeric)
%     Scales      - Optional scale specifier ([], or numeric)
%     NotNull     - Logical flag indicating NOT NULL constraint
%     PrimaryKey - Logical flag indicating PRIMARY KEY
%
%   Inputs:
%     tableMeta  - Table containing column metadata (see example below)
%     tableName  - Name of the table to be created
%     schemaName - PostgreSQL schema name
%
%   Output:
%     SQLCommand - SQL CREATE TABLE command as char
%
%   Example:
%     SQLCommand = generateSQLforTablecreation(tableMeta, 'ISValue', 'dbo');
%

    % Initialize CREATE TABLE statement
    SQLCommand = sprintf('CREATE TABLE IF NOT EXISTS "%s"."%s" (', schemaName, tableName);

    % Iterate over all column definitions
    for i = 1:height(tableMeta)
        columnDef = sprintf('"%s" %s', tableMeta.Names{i}, tableMeta.DataTypes{i});

        % Optional length specification
        if ~isempty(tableMeta.Lengths{i})
            columnDef = sprintf('%s(%d)', columnDef, tableMeta.Lengths{i});
        end

        % Optional scale specification
        if ~isempty(tableMeta.Scales{i})
            columnDef = sprintf('%s(%d)', columnDef, tableMeta.Scales{i});
        end

        % NOT NULL constraint
        if tableMeta.NotNull{i}
            columnDef = sprintf('%s NOT NULL', columnDef);
        end

        % PRIMARY KEY constraint
        if tableMeta.PrimaryKey{i}
            columnDef = sprintf('%s PRIMARY KEY', columnDef);
        end

        % Add comma except for last column
        if i < height(tableMeta)
            columnDef = sprintf('%s,', columnDef);
        end

        % Append column definition to SQL string
        SQLCommand = sprintf('%s %s', SQLCommand, columnDef);
    end

    % Close CREATE TABLE statement
    SQLCommand = sprintf('%s );', SQLCommand);
end
