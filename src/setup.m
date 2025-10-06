function setup()
% SETUP  Initializes the AutoQ MATLAB environment automatically.
%
%   This script:
%     - Searches upward from this file for the first folder whose name
%       contains "Auto"
%     - Changes the current folder to that project root
%     - Recursively adds all subfolders to the MATLAB path
%
%   You can run this from anywhere by typing: setup

    % 1) Determine where this file is located
    thisFile = mfilename('fullpath');
    thisFolder = fileparts(thisFile);

    % 2) Search upward for a folder whose name contains "Auto"
    currentFolder = thisFolder;
    projectRoot = '';
    while true
        [parent, name] = fileparts(currentFolder);

        if contains(name, 'Auto', 'IgnoreCase', true)
            projectRoot = currentFolder;
            break;
        end

        if strcmp(parent, currentFolder)
            % reached root of filesystem without finding a match
            break;
        end

        currentFolder = parent;
    end

    if isempty(projectRoot) || ~isfolder(projectRoot)
        error('Setup:ProjectRootNotFound', ...
              'No folder containing "Auto" found above "%s".', thisFolder);
    end

    % 3) Change MATLAB's current folder to the project root
    cd(projectRoot);

    % 4) Recursively add all subfolders to the MATLAB path
    addpath(genpath(projectRoot));

    % 5) Print setup info
    fprintf('✅ Auto project setup completed successfully.\n');
    fprintf('📂 Project root: %s\n', projectRoot);
    fprintf('➕ Paths added (recursively): %d entries\n', ...
        numel(strsplit(path, pathsep)));
end
