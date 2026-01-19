% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function runsqlfile(filepath, Parameters)
%RUNSQLFILE  Execute SQL commands from a file using psql.
%   runsqlfile(filepath, Parameters)
%
%   Connects to a PostgreSQL database via the psql CLI and executes all SQL
%   commands from the specified file. If execution fails, the SQL file is
%   moved to a "failed" folder for later inspection.
%
%   Inputs:
%     filepath   - Full path to the SQL file to be executed
%     Parameters - Struct containing database and tool configuration:
%                  Parameters.database.host
%                  Parameters.database.port
%                  Parameters.database.username
%                  Parameters.database.password
%                  Parameters.database.dbname
%                  Parameters.path.psqlExe
%                  Parameters.path.program
%

    %disp('Saving data in the database');

    try
        % Provide password to psql via environment variable (session scope)
        setenv('PGPASSWORD', Parameters.database.password);

        % Build psql execution command
        command = sprintf('"%s" -h "%s" -p "%s" -U "%s" -d "%s" -f "%s"', ...
            Parameters.path.psqlExe, ...
            Parameters.database.host, ...
            Parameters.database.port, ...
            Parameters.database.username, ...
            Parameters.database.dbname, ...
            filepath);

        % Execute SQL file
        [status, cmdout] = system(command);

        % Evaluate command result
        if status == 0
            % Detect common error indicators in psql output
            if contains(cmdout, 'FEHLER') || contains(cmdout, 'ERROR')
                error('Error executing SQL commands.');
            else
                disp('SQL commands executed successfully - data was saved.');
            end
        else
            error('Error executing SQL commands.');
        end

        fclose('all');
        delete(filepath);

    catch
        % On failure, move the SQL file to a dedicated folder
        [~, name, ext] = fileparts(filepath);
        filenameWithExtension = name + ext;

        newFilePath = fullfile(char(Parameters.path.program), 'src', 'database', 'failed', filenameWithExtension);
        movefile(char(filepath), char(newFilePath), 'f');

        warning('Error saving data in the database. The SQL command file was saved under %s', newFilePath);
    end
end
