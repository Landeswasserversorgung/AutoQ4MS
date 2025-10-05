function newFilesPaths = ListAllFinishedFiles(srcDir, destDir)
    % Check if the source directory exists
    if ~isfolder(srcDir)
        error('Source directory does not exist: %s', srcDir);
    end

    % Create the destination directory if it does not exist
    if ~isfolder(destDir)
        mkdir(destDir);
    end

    % Initialize the output cell array
    newFilesPaths = "";

    % Get all contents in the source directory
    srcContents = dir(srcDir);
    dates = [srcContents.datenum];                % Numeric datenum values
    datetimeArray = datetime(dates, 'ConvertFrom', 'datenum');
    datetimeArray = transpose(datetimeArray);
    % assign us locale datetime
    for k=1:numel(datetimeArray)
        srcContents(k).date = char(datetimeArray(k));
    end
    % Find the current sample name based on the .bak file
    currentSampleName = 'noSampleDataIsWritten';
    for i = 1:numel(srcContents)
        [~, name, ext] = fileparts(srcContents(i).name);
        if strcmp(ext, '.bak')
            currentSampleName = name(1:end-6); % Remove ".wiff" from the name
            break;
        end
    end

    % Loop through all items in the source directory
    for i = 1:length(srcContents)
        % Skip '.', '..' and files related to the current sample
        if strcmp(srcContents(i).name, '.') || strcmp(srcContents(i).name, '..') || contains(srcContents(i).name, currentSampleName)
            continue;
        end

        % Construct full paths for source and destination
        srcItem = fullfile(srcDir, srcContents(i).name);
        destItem = fullfile(destDir, srcContents(i).name);

        if srcContents(i).isdir
            % If it's a directory, create it in the destination
            if ~isfolder(destItem)
                mkdir(destItem);
            end
            % Recursively process its contents
            SubfolderFilesList = ListAllFinishedFiles(srcItem, destItem);
            newFilesPaths = [newFilesPaths; SubfolderFilesList];
        else
            % Check if the file was modified more than 1 minute ago
            try
                fileDateTime = datetime(srcContents(i).date, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
            catch
                fileDateTime = datetime(srcContents(i).date, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss', 'Locale', 'de_DE');
            end

            if minutes(datetime('now') - fileDateTime) < 1
                continue; % Skip recently modified files
            end

            % Only add to list if file does not already exist in destination
            if ~exist(destItem, 'file')
                newFilesPaths = [newFilesPaths; string(srcItem)];
            end
        end
    end

    % Convert the output to a string array
    newFilesPaths = string(newFilesPaths);
end
