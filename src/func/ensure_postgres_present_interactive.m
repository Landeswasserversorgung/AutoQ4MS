% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function psql = ensure_postgres_present_interactive()
% ENSURE_POSTGRES_PRESENT_INTERACTIVE
% Checks if PostgreSQL (psql.exe) is available on the system.
% - If found: returns the full path and adds its folder to the PATH for the current MATLAB session.
% - If not found: presents a dialog with options:
%     [Download & Open]  -> Downloads the official 17.6 installer and launches it (GUI),
%                           then re-checks after user confirmation.
%     [Browse psql.exe]  -> Allows the user to manually select an existing psql.exe.
%     [Cancel]           -> Cancels (psql = "").
%
% Return:
%   psql (string): full path to psql.exe or "" if not found or cancelled.
%

    fprintf('\n--- Checking for PostgreSQL (psql) ---\n');

    % 1) Already installed?
    psql = find_psql();
    if psql ~= ""
        fprintf('PostgreSQL detected: %s\n', psql);
        addDirToSessionPath(fileparts(psql));
        return
    end

    % 2) Not found → offer options to the user
    resp = questdlg( ...
        sprintf(['PostgreSQL 17.x was not found on this system.\n\n' ...
                 'Stack Builder is NOT required for this application.\n\n' ...
                 'Choose one of the following options:\n' ...
                 '• Download & Open: download and run the official installer\n' ...
                 '• Browse psql.exe: manually select an existing psql.exe']), ...
        'PostgreSQL Installer', ...
        'Download & Open', 'Browse psql.exe', 'Cancel', ...
        'Download & Open');

    switch resp
        case 'Download & Open'
            psql = do_download_and_open_installer_then_recheck();
            % psql will either be set or "" (if user cancels or installation fails)

        case 'Browse psql.exe'
            psql = browse_for_psql();
            if psql ~= ""
                addDirToSessionPath(fileparts(psql));
                fprintf('PostgreSQL set: %s\n', psql);
            else
                warning('No file selected. PostgreSQL not set.');
            end

        otherwise % 'Cancel' or dialog closed
            fprintf('Canceled by user. No changes made.\n');
            psql = "";
    end
end

% ----------------- Helper Functions -----------------
function psql = do_download_and_open_installer_then_recheck()
    % Official EnterpriseDB installer (17.6 x64)
    url     = "https://get.enterprisedb.com/postgresql/postgresql-17.6-2-windows-x64.exe";
    exeFile = fullfile(tempdir, "postgresql-17.6-2-windows-x64.exe");
    psql    = "";

    % a) Download the installer
    try
        if ~isfile(exeFile)
            fprintf('Downloading installer to: %s\n', exeFile);
            websave(exeFile, url);
        else
            fprintf('Installer already present at: %s\n', exeFile);
        end
    catch ME
        warning('Download failed: %s', char(ME.message));
        web(url, '-browser'); % open browser as fallback
        uiwait(warndlg({'Download opened in your browser.', ...
                        'Please install PostgreSQL manually, then click OK to continue.'}, ...
                        'Manual download'));
        % continue to (c): after OK, re-check installation
    end

    % b) Launch the GUI installer (if downloaded successfully)
    if isfile(exeFile)
        try
            % "start" runs the installer detached from MATLAB
            system(sprintf('start "" "%s"', exeFile));
        catch
            try, winopen(exeFile); catch, end
        end
    end

    % c) Ask the user to finish installation and re-check afterwards
    uiwait(msgbox({ ...
        'Please complete the PostgreSQL setup wizard.', ...
        'If a reboot is requested, please reboot and reopen MATLAB afterwards.', ...
        '', ...
        'Click OK here once you have finished the installation to re-check.'}, ...
        'Continue after installation','help'));

    % d) Re-check for psql.exe
    p = find_psql();
    if p ~= ""
        addDirToSessionPath(fileparts(p));
        fprintf('PostgreSQL detected after installation: %s\n', p);
        psql = p;
        return
    end

    % e) Still not found → let user manually select
    uiwait(warndlg({'PostgreSQL (psql) was not detected yet.', ...
                    'Please select psql.exe manually.'}, ...
                    'Manual selection required'));
    p = browse_for_psql();
    if p ~= ""
        addDirToSessionPath(fileparts(p));
        fprintf('PostgreSQL set manually: %s\n', p);
        psql = p;
    else
        warning('PostgreSQL could not be set.');
        psql = "";
    end
end

function psql = browse_for_psql()
    % Opens a file browser to let the user select psql.exe manually
    [f, fp] = uigetfile({'psql.exe','psql.exe'}, 'Please select psql.exe');
    if isequal(f,0)
        psql = "";
        return
    end
    p = string(fullfile(fp,f));
    if isfile(p)
        psql = p;
    else
        psql = "";
    end
end

function psql = find_psql()
% Searches for psql.exe using PATH and common installation directories.
    psql = "";
    [st, res] = system('where psql');
    if st == 0
        L = strtrim(splitlines(string(res))); L = L(L ~= "");
        if ~isempty(L), psql = L(1); return; end
    end
    candidates = [
        "C:\Program Files\PostgreSQL\17\bin\psql.exe"
        "C:\Program Files\PostgreSQL\16\bin\psql.exe"
        "C:\Program Files\PostgreSQL\bin\psql.exe"
        "C:\PostgreSQL\17\bin\psql.exe" % optional fallback
    ];
    for c = candidates(:)'
        if isfile(c), psql = c; return; end
    end
end

function addDirToSessionPath(dirPath)
% Adds the given directory to MATLAB's PATH for the current session only.
% This does not require administrator rights and does not affect the system PATH.
    newPath = string(dirPath) + ";" + string(getenv("PATH"));
    setenv("PATH", newPath);
end
