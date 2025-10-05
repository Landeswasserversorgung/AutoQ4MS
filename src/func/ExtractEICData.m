function [scanTimes, ionIntensities] = ExtractEICData(extracted_ms_data, target_mz, varargin)
% ExtractEICData Extracts ion intensities for a specific m/z value across scans
% This function searches through MS data to find and sum the intensities of ions
% that fall within a specified m/z tolerance of a target m/z value.
% Linus Strähle 2024-04-02
%
% Inputs:
%   extracted_ms_data - Struct array containing MS scan data. Each element should
%                       have a 'ScanData' field with m/z values (column 1) and
%                       their corresponding intensities (column 2).
%   target_mz         - The m/z value for which to extract ion intensities.
%   varargin          - Optional argument to specify the m/z tolerance. If not
%                       provided, a default value of 0.005 is used.
%
% Outputs:
%   scanTimes        - Vector containing the retention times for each scan.
%   ionIntensities   - Vector containing the summed ion intensities for the target
%                      m/z value within the specified tolerance for each scan.

% Handle the optional m/z tolerance parameter
if length(varargin) >= 1
    mz_tolerance = varargin{1};
else
    mz_tolerance = 0.005; % Default m/z tolerance if not specified
end

numScans = length(extracted_ms_data); % Determine the number of scans
% Correct initialization of ionIntensities and scanTimes vectors
ionIntensities = zeros(numScans, 1); % Initialize vector for ion intensities
scanTimes = zeros(numScans, 1); % Initialize vector for retention times

for i = 1:numScans
    % Access the 'ScanData' of the current scan
    % Corrected to access the i-th scan instead of always the first one
    mzValues = extracted_ms_data(i).ScanData(:,1);
    intensityValues = extracted_ms_data(i).ScanData(:,2);
    
    % Initialize variable to sum intensities for ions close to target_mz
    sum_intensity = 0;
    
    % Iterate over all m/z values in the current scan
    for j = 1:numel(mzValues) 
        % If the current m/z value is within the tolerance of target_mz,
        % add its intensity to sum_intensity
        if abs(mzValues(j) - target_mz) <= mz_tolerance 
            sum_intensity = sum_intensity + intensityValues(j);
        end
    end 
    
    % Store the summed intensity for the current scan
    ionIntensities(i) = sum_intensity;
    % Optionally, you might want to store retention times if available,
    scanTimes(i) = extracted_ms_data(i).retentionTime;
end
end



