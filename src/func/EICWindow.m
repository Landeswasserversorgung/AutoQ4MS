function [newscanTimes, newionIntensities] = EICWindow(scanTimes, ionIntensities, lower_time_Sec, upper_time_Sec)
% EICWindow Extracts a window of ion intensities and scan times based on specified time bounds.
% This function receives two vectors, scanTimes and ionIntensities, along with lower and upper time bounds in seconds.
% It filters both vectors to only include the data within the specified time window, converting seconds to minutes for comparison.
% Linus Strähle 2024-03-29

    % Convert the lower and upper time bounds from seconds to minutes
    % This is necessary because scanTimes are assumed to be in minutes
    start = lower_time_Sec/60;
    end_time = upper_time_Sec/60;
    
    
%     if start < 300
%         disp('Access to MS data that is not available');
%         newscanTimes = NaN;
%         newionIntensities = NaN;
%         return
%     end
    % Find the indices of scanTimes that fall within the specified interval
    % This logical array identifies the positions in scanTimes that are within the [start, end_time] window
    intervall_indices = (scanTimes >= start) & (scanTimes <= end_time); 
    
    % Filter both the ionIntensities and scanTimes vectors using the identified indices
    % This results in new vectors that only contain data within the specified time window
    newionIntensities = ionIntensities(intervall_indices);
    newscanTimes = scanTimes(intervall_indices);

end

