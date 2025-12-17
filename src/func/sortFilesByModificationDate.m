function sortedFilePaths = sortFilesByModificationDate(filePaths, Parameters)
%SORTFILESBYMODIFICATIONDATE  Sort file paths by modification date or name.
%
%   sortedFilePaths = sortFilesByModificationDate(filePaths, Parameters)
%
%   Sorts a list of file paths either by their last modification date
%   (oldest first) or alphabetically by filename, depending on the
%   configuration in Parameters.General.SampleOrder.
%
%   Inputs:
%     filePaths  - Cell array or string array of file paths
%     Parameters - Project parameters struct containing:
%                  Parameters.General.SampleOrder
%                  0 = sort by modification date
%                  1 = sort by filename
%
%   Output:
%     sortedFilePaths - Sorted list of file paths
%

    numFiles = length(filePaths);
    modificationDates = NaT(1, numFiles); % Preallocate datetime array

    if Parameters.General.SampleOrder == 0
        %% Sort by modification date

        for i = 1:numFiles
            fileInfo = dir(filePaths{i}); % Get file information
            fileDateNum = fileInfo.datenum;

            modificationDates(i) = datetime( ...
                fileDateNum, ...
                'ConvertFrom', 'datenum', ...
                'InputFormat', 'dd-MMM-yyyy HH:mm:ss', ...
                'Locale', 'en_US' ...
            );
        end

        % Sort by date (oldest first)
        [~, sortIdx] = sort(modificationDates);
        sortedFilePaths = filePaths(sortIdx);

    elseif Parameters.General.SampleOrder == 1
        %% Sort by filename
        sortedFilePaths = sort(filePaths, 2, "ascend");
    end
end



