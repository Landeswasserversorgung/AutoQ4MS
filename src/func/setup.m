function setup()
% SETUP  Initializes the AutoQ MATLAB environment.
%
%   This script:
%     - Detects the project root (one level above /src)
%     - Changes the current folder to the project root
%     - Recursively adds all subfolders to the MATLAB path
%
%   Place this file in: AutoQ/src/setup.m
%   Run it from anywhere by typing: setup

    % 1) Determine the project root (one level above /src)
    thisFile   = mfilename('fullpath');
    srcFolder  = fileparts(thisFile);
    projectRoot = fileparts(srcFolder);  % -> AutoQ

    if ~isfolder(projectRoot)
        error('Setup:ProjectRootNotFound', ...
              'Project root "%s" could not be found.', projectRoot);
    end

    % 2) Change MATLAB's current folder to the project root
    cd(projectRoot);

    % 3) Recursively add all subfolders to the MATLAB path
    addpath(genpath(projectRoot));

    % 4) Print setup info
    fprintf('✅ AutoQ setup completed successfully.\n');
    fprintf('📂 Project root: %s\n', projectRoot);
    fprintf('➕ Paths added (recursively): %d entries\n', ...
        numel(strsplit(path, pathsep)));
end
