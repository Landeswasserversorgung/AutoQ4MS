function msconvPath = ensure_msconvert_interactive(msiUrl)
% ENSURE_MSCONVERT_INTERACTIVE
% User-friendly checker/installer for ProteoWizard MSConvert on Windows.
%
% Behavior:
%   - If msconvert.exe exists -> returns its full path and prepends its folder
%     to the current MATLAB session PATH.
%   - Else asks user: install now?
%       * Yes  -> download official MSI, launch GUI installer, re-check afterwards.
%       * No   -> ask user to manually browse to msconvert.exe.
%
% Return:
%   msconvPath (string): full path to msconvert.exe, or "" if not set/found.
%
% Usage:
%   url = "https://mc-tca-01.s3.us-west-2.amazonaws.com/ProteoWizard/bt83/3698364/pwiz-setup-3.0.25286.0edf8b7-x86_64.msi";
%   msconvPath = ensure_msconvert_interactive(url);
%

    if nargin < 1 || strlength(string(msiUrl)) == 0
        % Fallback to a known stable MSI URL (adjust to your preferred source)
        msiUrl = "https://mc-tca-01.s3.us-west-2.amazonaws.com/ProteoWizard/bt83/3698364/pwiz-setup-3.0.25286.0edf8b7-x86_64.msi";
    end

    fprintf('\n--- Checking MSConvert ---\n');

    % 1) Already installed?
    msconvPath = find_msconvert();
    if msconvPath ~= ""
        fprintf('MSConvert found: %s\n', msconvPath);
        addDirToSessionPath(fileparts(msconvPath));
        return
    end

    % 2) Ask user if we should install now
    choice = questdlg( ...
        ['MSConvert was not found on this system.', newline, ...
         'Do you want to download and open the official installer now?'], ...
        'MSConvert Installation', 'Yes', 'No', 'Yes');

    if strcmp(choice, 'Yes')
        % a) Download MSI into temp
        msiFile = fullfile(tempdir, "msconvert_installer.msi");
        try
            fprintf('Downloading installer...\n');
            websave(msiFile, msiUrl);
            fprintf('Saved to: %s\n', msiFile);
        catch ME
            warning('Download failed: %s', char(ME.message));
            uiwait(warndlg({ ...
                'Automatic download failed.', ...
                'The official download page will open in your browser.', ...
                'Please download and run the MSI manually.'}, ...
                'Download failed'));
            web(msiUrl, '-browser');
            msiFile = "";
        end

        % b) Launch GUI installer
        if msiFile ~= "" && isfile(msiFile)
            try
                fprintf('Launching installer (GUI)...\n');
                system(sprintf('start "" "%s"', msiFile));   % starts the MSI GUI
            catch
                try
                    winopen(msiFile);
                catch
                    web(msiUrl, '-browser');
                end
            end
        end

        % c) Let user finish, then re-check
        uiwait(msgbox({ ...
            'Please complete the MSConvert setup wizard.', ...
            'If a reboot is requested, please reboot first.', ...
            '', ...
            'Click OK here after the installation has finished.'}, ...
            'Continue after installation','help'));

        msconvPath = find_msconvert();
        if msconvPath ~= ""
            fprintf('MSConvert found after installation: %s\n', msconvPath);
            addDirToSessionPath(fileparts(msconvPath));
            return
        else
            % d) Still not found -> manual browse
            uiwait(warndlg({ ...
                'MSConvert was still not found.', ...
                'Please select msconvert.exe manually.'}, ...
                'Manual selection required'));
            msconvPath = browse_for_msconvert();
            if msconvPath ~= ""
                addDirToSessionPath(fileparts(msconvPath));
                fprintf('MSConvert set manually: %s\n', msconvPath);
            else
                warning('MSConvert could not be set.');
            end
            return
        end

    else
        % User chose "No" -> manual installation + browse
        uiwait(warndlg({ ...
            'Please install ProteoWizard/MSConvert manually using the official installer.', ...
            'Afterwards, select msconvert.exe when prompted.'}, ...
            'Manual installation'));
        msconvPath = browse_for_msconvert();
        if msconvPath ~= ""
            addDirToSessionPath(fileparts(msconvPath));
            fprintf('MSConvert set manually: %s\n', msconvPath);
        else
            warning('MSConvert could not be set.');
        end
        return
    end
end

%% ----------------- Helpers -----------------
function addDirToSessionPath(dirPath)
% Safely prepend a folder to the PATH for the current MATLAB session.
    newPath = string(dirPath) + ";" + string(getenv("PATH"));
    setenv("PATH", newPath);
end

function p = browse_for_msconvert()
% Prompt the user to select msconvert.exe and validate the selection.
    [f,fp] = uigetfile({'msconvert.exe','msconvert.exe'}, 'Please select msconvert.exe');
    if isequal(f,0)
        p = "";
        return
    end
    p = string(fullfile(fp,f));
    if ~isfile(p)
        p = "";
    end
end
