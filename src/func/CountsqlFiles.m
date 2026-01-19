% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function count = CountsqlFiles(folderPath)
%COUNTSQLFILES  Count the number of .sql files in a folder (non-recursive).
%   Verifies that the specified folder exists and counts all files with
%   the ".sql" extension located directly within it (no subfolders).
%
%   Input:
%     folderPath - Path to the folder to scan (char or string)
%
%   Output:
%     count - Number of .sql files found in the folder
%
%   Example:
%     nSQL = CountsqlFiles("C:\projects\database\scripts");
%

    % Ensure the input is a character vector
    folderPath = char(folderPath);

    % Validate that the folder exists
    if ~isfolder(folderPath)
        error('Folder does not exist: %s', folderPath);
    end

    % Find all .sql files in the given folder (non-recursive)
    sqlFiles = dir(fullfile(folderPath, '*.sql'));

    % Return the number of found .sql files
    count = numel(sqlFiles);
end
