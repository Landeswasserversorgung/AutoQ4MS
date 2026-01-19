% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function exe = find_msconvert()
%FIND_MSCONVERT  Locate the path to ProteoWizard's msconvert.exe on Windows.
%
%   This function attempts to locate msconvert.exe by:
%     A) Checking if it is available in the system PATH ("where" command)
%     B) Searching common installation directories under Program Files
%     C) Looking for user-local installs under AppData
%     D) As a fallback, recursively scanning Program Files folders
%
%   Returns:
%     exe (string) - Full path to msconvert.exe
%                    Empty string "" if not found
%
%   Example:
%     exe = find_msconvert();
%     if exe == ""
%         warning('MSConvert not found on this system.');
%     else
%         fprintf('MSConvert found: %s\n', exe);
%     end
%

    exe = "";

    %% A) Check if msconvert is in PATH
    [status, output] = system('where msconvert');
    if status == 0
        lines = strtrim(splitlines(string(output)));
        lines = lines(lines ~= "");
        if ~isempty(lines)
            exe = lines(1);
            return;
        end
    end

    %% B) Common installation directories (Program Files)
    candidates = [
        "C:\Program Files\ProteoWizard\ProteoWizard 64-bit\msconvert.exe"
        "C:\Program Files\ProteoWizard\msconvert.exe"
        "C:\Program Files (x86)\ProteoWizard\ProteoWizard 64-bit\msconvert.exe"
        "C:\Program Files (x86)\ProteoWizard\msconvert.exe"
    ];

    for c = candidates(:)'
        if isfile(c)
            exe = c;
            return;
        end
    end

    %% C) User-specific installation (non-admin setup)
    localAppData = getenv('LOCALAPPDATA'); % e.g. C:\Users\<User>\AppData\Local
    if ~isempty(localAppData)
        d = dir(fullfile(localAppData, "Programs", "ProteoWizard", "**", "msconvert.exe"));
        if ~isempty(d)
            % Choose most recently modified file
            [~, idx] = max([d.datenum]);
            exe = fullfile(d(idx).folder, d(idx).name);
            return;
        end
    end

    %% D) Fallback: recursive search under Program Files
    roots = ["C:\Program Files\ProteoWizard", "C:\Program Files (x86)\ProteoWizard"];
    for r = roots
        if isfolder(r)
            d = dir(fullfile(r, "**", "msconvert.exe"));
            if ~isempty(d)
                [~, idx] = max([d.datenum]);
                exe = fullfile(d(idx).folder, d(idx).name);
                return;
            end
        end
    end
end
