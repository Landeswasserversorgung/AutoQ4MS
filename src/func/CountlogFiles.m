function count = CountlogFiles(folderPath)
%COUNTLOGFILES  Count the number of .log files in a folder (non-recursive).
%   Checks whether the specified folder exists and counts all files with
%   the ".log" extension located directly within it (no subfolders).
%
%   Input:
%     folderPath - Path to the folder to scan (char or string)
%
%   Output:
%     count - Number of .log files found in the folder
%
%   Example:
%     nLogs = CountlogFiles("C:\data\logs");
%

    % Ensure the input is a character vector
    folderPath = char(folderPath);

    % Validate folder existence
    if ~isfolder(folderPath)
        error('Folder does not exist: %s', folderPath);
    end

    % Find all .log files in the given folder (non-recursive)
    logFiles = dir(fullfile(folderPath, '*.log'));

    % Return the number of found .log files
    count = numel(logFiles);
end

