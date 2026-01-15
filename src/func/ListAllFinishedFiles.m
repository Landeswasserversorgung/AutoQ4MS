function newFilesPaths = ListAllFinishedFiles(srcDir, destDir)
%LISTALLFINISHEDFILES  Recursively list files that appear "finished" and are not yet in destination.
%
%   newFilesPaths = ListAllFinishedFiles(srcDir, destDir)
%   Recursively scans a source directory and returns a list of file paths that:
%     - are NOT related to the currently written sample (derived from a .bak file),
%     - were not modified within the last minute,
%     - and do not yet exist in the destination directory.
%
%   Inputs:
%     srcDir  - Source directory to scan
%     destDir - Destination directory used to check whether files already exist
%
%   Output:
%     newFilesPaths - String array of file paths in srcDir that meet the criteria
%

    % Check if the source directory exists
    if ~isfolder(srcDir)
        error('Source directory does not exist: %s', srcDir);
    end

    % Create the destination directory if it does not exist
    if ~isfolder(destDir)
        mkdir(destDir);
    end

    % Initialize output (string array style)
    newFilesPaths = "";

    % List directory contents
    srcContents = dir(srcDir);

    % Convert datenum to datetime and store back into srcContents(i).date (char)
    dates = [srcContents.datenum];
    datetimeArray = datetime(dates, 'ConvertFrom', 'datenum', 'Format', 'dd-MM-yyyy HH:mm:ss');
    datetimeArray = transpose(datetimeArray);

    for k = 1:numel(datetimeArray)
        srcContents(k).date = char(datetimeArray(k));
    end

    %% Determine the current sample name based on a .bak file
    currentSampleName = 'noSampleDataIsWritten';
    for i = 1:numel(srcContents)
        [~, name, ext] = fileparts(srcContents(i).name);
        if strcmp(ext, '.bak')
            currentSampleName = name(1:end-6); % Remove ".wiff" from the name
            break;
        end
    end

    %% Loop through all items in the source directory
    for i = 1:length(srcContents)

        % Skip '.', '..' and files related to the current sample
        if strcmp(srcContents(i).name, '.') || strcmp(srcContents(i).name, '..') || ...
           contains(srcContents(i).name, currentSampleName)
            continue;
        end

        % Build full paths for source and destination items
        srcItem  = fullfile(srcDir, srcContents(i).name);
        destItem = fullfile(destDir, srcContents(i).name);

        if srcContents(i).isdir
            % Mirror directories in destination and recurse
            if ~isfolder(destItem)
                mkdir(destItem);
            end

            subfolderFilesList = ListAllFinishedFiles(srcItem, destItem);
            newFilesPaths = [newFilesPaths; subfolderFilesList];

        else
            % Check if the file was modified more than 1 minute ago
            try
                fileDateTime = datetime(srcContents(i).date, 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
            catch
                fileDateTime = datetime(srcContents(i).date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
                %fileDateTime = datetime(srcContents(i).date, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss', 'Locale', 'de_DE');
            end

            if minutes(datetime('now') - fileDateTime) < 1
                continue; % Skip recently modified files
            end

            % Only add if file does not already exist in destination
            if ~exist(destItem, 'file')
                newFilesPaths = [newFilesPaths; string(srcItem)];
            end
        end
    end

    % Ensure output is a string array
    newFilesPaths = string(newFilesPaths);
end

