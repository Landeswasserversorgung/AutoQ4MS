function exe = find_msconvert()
% FIND_MSCONVERT  Locate the path to ProteoWizard's msconvert.exe on Windows.
%
% This function searches for msconvert.exe using several strategies:
%   A) Checks if it's available in the system PATH (via "where" command)
%   B) Looks in common installation directories under "Program Files"
%   C) Searches the user's local AppData (for non-admin installs)
%   D) As a last resort, performs a recursive search under Program Files
%
% Returns:
%   exe - full path to msconvert.exe (string)
%         empty string "" if not found
%
% Example:
%   exe = find_msconvert();
%   if exe == ""
%       warning('MSConvert not found on this system.');
%   else
%       fprintf('MSConvert found: %s\n', exe);
%   end

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

    %% B) Check common installation directories (Program Files)
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

    %% C) Check user-specific installation (non-admin setup)
    localAppData = getenv('LOCALAPPDATA'); % e.g. C:\Users\<User>\AppData\Local
    if ~isempty(localAppData)
        d = dir(fullfile(localAppData, "Programs", "ProteoWizard", "**", "msconvert.exe"));
        if ~isempty(d)
            % Pick the most recently modified one
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
