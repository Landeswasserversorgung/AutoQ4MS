function count = CountsqlFiles(folderPath)
    % Ensure the input is a char array
    folderPath = char(folderPath);

    % Check if the folder exists
    if ~isfolder(folderPath)
        error('Folder does not exist: %s', folderPath);
    end

    % Search for all .txt files in the folder (non-recursive)
    sqlFiles = dir(fullfile(folderPath, '*.sql'));

    % Return the number of found files
    count = numel(sqlFiles);
end

