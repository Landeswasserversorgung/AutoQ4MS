function sortedFilePaths = sortFilesByModificationDate(filePaths,Parameters)
    % sortFilesByModificationDate Sorts a list of file paths by last modification date.
    % 
    % INPUT:
    %   filePaths - A cell array or string array of file paths (e.g., {"path/to/file1", "path/to/file2"}).
    %
    % OUTPUT:
    %   sortedFilePaths - A cell array or string array of file paths sorted by modification date (oldest first).

    % Initialize an array to hold the modification dates
    numFiles = length(filePaths);
    modificationDates = NaT(1, numFiles); % NaT: Not-a-Time for datetime array
    if Parameters.General.SampleOrder == 0 % Sort by Modification Date
   

    % Loop through each file path to retrieve the modification date
    for i = 1:numFiles
        fileInfo = dir(filePaths{i});  % Get file information 
        %try 
        fileDateNum = fileInfo.datenum;
        modificationDates(i) = datetime(fileDateNum, 'ConvertFrom', 'datenum', 'InputFormat', 'dd-MMM-yyyy HH:mm:ss', 'Locale', 'en_US');
            
            %datetime(fileInfo.date, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss', 'Locale', 'en_US');
        %catch
            %modificationDates(i) = datetime(fileInfo.datenum, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss', 'Locale', 'de_DE');
        %end
    end
    
    % Sort the file paths by modification dates
    [~, sortIdx] = sort(modificationDates);  % Get indices of sorted dates
    sortedFilePaths = filePaths(sortIdx);  % Sort the file paths accordingly
    elseif Parameters.General.SampleOrder == 1 % Sort by Name
        sortedFilePaths = sort(filePaths,2,"ascend");
    % Display sorted file paths (optional)
    % disp('Sorted file paths (oldest modification date first):');
    % disp(sortedFilePaths);
    end
end


