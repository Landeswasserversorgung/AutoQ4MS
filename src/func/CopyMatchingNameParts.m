% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function CopiedFiles = CopyMatchingNameParts(filePath, destDir, srcDir)
%COPYMATCHINGNAMEPARTS  Copy files whose names contain a given substring.
%   Copies all files from a source directory (recursively) whose filenames
%   contain the same name part as a reference file. Maintains subfolder
%   structure when copying into the destination directory.
%
%   Inputs:
%     filePath - Full path to the reference file
%     destDir  - Destination directory where matching files are copied
%     srcDir   - Root source directory to search within (recursively)
%
%   Output:
%     CopiedFiles - String array of full paths to all copied files
%
%   Example:
%     CopyMatchingNameParts("C:\data\run1\sampleA.raw", ...
%                           "C:\backup\", ...
%                           "C:\data\")
%

    % Ensure inputs are character vectors
    filePath = char(filePath);
    destDir  = char(destDir);
    srcDir   = char(srcDir);

    % Extract filename (without extension or path)
    [~, fileName, ~] = fileparts(filePath);

    % Validate that source directory exists
    if ~isfolder(srcDir)
        error('Source directory does not exist: %s', srcDir);
    end

    % Ensure that destination directory exists (create if needed)
    if ~isfolder(destDir)
        mkdir(destDir);
    end

    % Recursively list all files under srcDir
    allFiles = dir(fullfile(srcDir, '**', '*'));

    % Initialize output container
    CopiedFiles = {};

    for i = 1:length(allFiles)
        if allFiles(i).isdir
            continue; % Skip folders
        end

        % Check if the filename contains the reference name part
        if contains(allFiles(i).name, fileName)
            fullSrcPath = fullfile(allFiles(i).folder, allFiles(i).name);

            % Build relative path (preserve subdirectory structure)
            relativePath = erase(fullSrcPath, srcDir);
            if startsWith(relativePath, filesep)
                relativePath = relativePath(2:end);
            end

            % Build full destination path
            fullDestPath = fullfile(destDir, relativePath);

            % Ensure destination folder exists
            destFolder = fileparts(fullDestPath);
            if ~isfolder(destFolder)
                mkdir(destFolder);
            end

            % Copy the file and log to console
            copyfile(fullSrcPath, fullDestPath);
            disp(['Copied: ', fullDestPath]);

            % Add path to output list
            CopiedFiles{end+1} = fullDestPath; %#ok<AGROW>
        end
    end

    % Convert list to string array
    CopiedFiles = string(CopiedFiles);


end
