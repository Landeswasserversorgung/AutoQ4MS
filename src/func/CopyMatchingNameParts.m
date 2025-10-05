function CopiedFiles = CopyMatchingNameParts(filePath, destDir, srcDir)

    % Ensure char types
    filePath = char(filePath);
    destDir = char(destDir);
    srcDir = char(srcDir);

    % Extract filename (without path)
    [~, fileName, ~] = fileparts(filePath);

    % Make sure the source directory exists
    if ~isfolder(srcDir)
        error('Source directory does not exist: %s', srcDir);
    end

    % Make sure destination root exists
    if ~isfolder(destDir)
        mkdir(destDir);
    end

    % Recursively list all files under srcDir
    allFiles = dir(fullfile(srcDir, '**', '*'));

    % Init output
    CopiedFiles = {};

    for i = 1:length(allFiles)
        if allFiles(i).isdir
            continue; % skip folders
        end

        % Check if file name contains the target name
        if contains(allFiles(i).name, fileName)
            fullSrcPath = fullfile(allFiles(i).folder, allFiles(i).name);

            % Build relative path from srcDir
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

            % Copy the file
            copyfile(fullSrcPath, fullDestPath);
            disp(['Copied: ', fullDestPath]);

            % Add to list
            CopiedFiles{end+1} = fullDestPath;
        end
    end

    % Convert to string array
    CopiedFiles = string(CopiedFiles);
end

