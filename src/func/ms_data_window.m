function filtered_ms_data = ms_data_window(ms_data, Window_sec)
%% This function filters MS data based on a specified retention time window.
% Linus Strähle 2024-04-02
% Inputs:
%   ms_data - Struct array containing MS data, each struct should have at least
%             a 'retentionTime' field among other fields like 'polarity' and 'ScanData'.
%   Window_sec - A 2-element vector specifying the start and end of the retention
%                time window in seconds. For example, [200 400] represents a window
%                from 200 to 400 seconds.
%
% Outputs:
%   filtered_ms_data - Struct array containing only the MS data entries that fall
%                      within the specified retention time window.

% Note: If retentionTime is stored in a non-numeric format (e.g., as strings),
% you need to convert it to numeric format first. This step depends on the format
% of your data. If retentionTime is already numeric, you can skip this step.
% Example for conversion (if needed): 
% retentionTimesNumeric = str2double(retentionTime); 

% Find indices of entries whose retentionTime is within the specified window
% The condition checks each entry's retentionTime against the start (Window_sec(1))
% and end (Window_sec(2)) of the window.
ind = find([ms_data.retentionTime] >= (Window_sec(1)/60) & [ms_data.retentionTime] <= (Window_sec(2))/60);

% Extract these entries from ms_data
% This creates a new array 'filtered_ms_data' containing only the data entries
% that meet the time window condition.
filtered_ms_data = ms_data(ind);
end

