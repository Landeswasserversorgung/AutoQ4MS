function msconvPath = ensure_msconvert_interactive(downloadUrl)
% ENSURE_MSCONVERT_INTERACTIVE
% User-friendly checker/installer for ProteoWizard MSConvert on Windows.
%
% Uses existing find_msconvert() function.
% Includes a simple runtime test: msconvert --version

    if nargin < 1 || strlength(string(downloadUrl)) == 0
        downloadUrl = "https://proteowizard.sourceforge.io/download.html";
    end

    fprintf('\n--- Checking MSConvert ---\n');

    % 1) Already installed?
    msconvPath = find_msconvert();   % <-- DEINE Funktion
    if msconvPath ~= ""
        if test_msconvert(msconvPath)
            fprintf('MSConvert working: %s\n', msconvPath);
            addDirToSessionPath(fileparts(msconvPath));
            return
        else
            warning('MSConvert was found but did not run correctly.');
        end
    end

    % 2) Ask user
    choice = questdlg( ...
        ['MSConvert was not found or did not run correctly.', newline, ...
         'Do you want to open the official download page now?'], ...
        'MSConvert Installation', 'Yes', 'No', 'Yes');

    if strcmp(choice, 'Yes')
        % Open browser
        try
            web(downloadUrl, '-browser');
        catch
            try
                winopen(char(downloadUrl));
            catch
                warning('Please open this URL manually:\n%s', downloadUrl);
            end
        end

        % Wait for user
        uiwait(msgbox({ ...
            'Please install ProteoWizard/MSConvert.', ...
            '', ...
            'Click OK once you are finished (even if you cancelled).' }, ...
            'Continue','help'));

        % Re-check
        msconvPath = find_msconvert();
        if msconvPath ~= "" && test_msconvert(msconvPath)
            addDirToSessionPath(fileparts(msconvPath));
            fprintf('MSConvert found and working: %s\n', msconvPath);
            return
        end

        % Manual browse
        uiwait(warndlg('Please select msconvert.exe manually.'));
        msconvPath = browse_for_msconvert();
        if msconvPath ~= "" && test_msconvert(msconvPath)
            addDirToSessionPath(fileparts(msconvPath));
            fprintf('MSConvert set manually: %s\n', msconvPath);
        else
            warning('MSConvert could not be set or did not run.');
            msconvPath = "";
        end
        return

    else
        % Manual path only
        uiwait(warndlg({ ...
            'Please install ProteoWizard/MSConvert manually.', ...
            'Then select msconvert.exe.'}));
        msconvPath = browse_for_msconvert();
        if msconvPath ~= "" && test_msconvert(msconvPath)
            addDirToSessionPath(fileparts(msconvPath));
            fprintf('MSConvert set manually: %s\n', msconvPath);
        else
            warning('MSConvert could not be set or did not run.');
            msconvPath = "";
        end
    end
end

%% ---- helpers ----
function addDirToSessionPath(dirPath)
    dirPath = string(dirPath);
    if dirPath == "" || ~isfolder(dirPath), return, end

    cur = string(getenv("PATH"));
    parts = split(cur, ";");
    if any(strcmpi(strtrim(parts), strtrim(dirPath))), return, end

    setenv("PATH", dirPath + ";" + cur);
end

function p = browse_for_msconvert()
    [f,fp] = uigetfile({'msconvert.exe','msconvert.exe'}, 'Select msconvert.exe');
    if isequal(f,0)
        p = "";
        return
    end
    p = string(fullfile(fp,f));
    if ~isfile(p)
        p = "";
    end
end

function ok = test_msconvert(msconvPath)
% Quick sanity check: run "msconvert --version"
    ok = false;
    try
        cmd = '"' + string(msconvPath) + '" --help';
        [st,out] = system(cmd);
        if st == 0 && contains(lower(out), "proteowizard")
            ok = true;
        end
    catch
        ok = false;
    end
end

