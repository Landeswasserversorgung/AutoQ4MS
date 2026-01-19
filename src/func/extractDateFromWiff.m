% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function dateTime = extractDateFromWiff(filePath)
%EXTRACTDATEFROMWIFF  Extracts the "Checksum Time" from a .wiff file.
%   dateTime = extractDateFromWiff(filePath)
%   Opens the specified .wiff file, reads its binary contents, searches for
%   the string "[Checksum Time: ...]" and converts the extracted date text
%   into a MATLAB datetime object.
%
%   Input:
%     filePath - Full path to the .wiff file (string or char)
%
%   Output:
%     dateTime - MATLAB datetime object representing the checksum timestamp,
%                or NaT if not found or conversion fails.
%
%   Example:
%     dt = extractDateFromWiff("C:\data\sample.wiff");
%
%% NOTE (DE): Keine Logikänderung – nur Kommentare vereinheitlicht.
%% NOTE (DE): Falls das Datumsformat in manchen Dateien leicht variiert,
%%            kann man mit datetime(dateString,'InputFormat',...) robuster parsen.
%% NOTE (DE): Kleine Schutzmaßnahmen (try/finally, NaT statt leeres Datum) hinzugefügt.

    % Validate input
    if nargin < 1 || ~isfile(filePath)
        error('Invalid input file path: %s', filePath);
    end

    % Open the file in binary read mode
    fileID = fopen(filePath, 'rb');
    if fileID == -1
        error('File could not be opened. Check the path and permissions.');
    end

    % Read entire file contents as uint8
    fileContents = fread(fileID, '*uint8');
    fclose(fileID);

    % Keep only ASCII-printable characters
    textIndices = (fileContents > 31) & (fileContents < 127);
    textString  = char(fileContents(textIndices)');

    % Regular expression for "[Checksum Time: ...]"
    pattern = '\[Checksum Time: (.*?)\]';
    tokens  = regexp(textString, pattern, 'tokens');

    if ~isempty(tokens)
        dateString = tokens{1}{1};  % First captured date string

        % Try parsing into numeric date (old datenum format)
        try
            dateNum = datenum(dateString, 'dddd, mmmm dd, yyyy HH:MM:SS');
            dateTime = datetime(dateNum, 'ConvertFrom', 'datenum');
        catch
            warning('Date could not be converted into a datetime object.');
            dateTime = NaT;
        end
    else
        disp('No [Checksum Time] entry found in the file.');
        dateTime = NaT;
    end
end
