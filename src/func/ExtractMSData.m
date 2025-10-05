function [scanTimes, ionIntensities] = ExtractMSData(extracted_ms_data, target_mz, varargin)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
if length(varargin) >= 1
        mz_tolerance = varargin{1};
else
    mz_tolerance = 0.005;
end

numScans = length(extracted_ms_data); % Number of Scans
ionIntensities = zeros(extracted_ms_data, 1); % Initialize vector for ion intensities
scanTimes = zeros(extracted_ms_data, 1); % Initialize vector for retention times


for i = 1:numScans
    % Access to the 'peaks' data of the current scan
    mzValues = extracted_ms_data(1).ScanData(:,1);
    intensityValues = extracted_ms_data(1).ScanData(:,2);
    sum_intensity = 0;
        for j = 1:numel(mzValues) 
            disp(mzValues);
            if abs(mzValues(j)-target_mz) <= mz_tolerance 
                sum_intensity = sum_intensity + intensityValues(j);
            end
        end 
    ionIntensities(i) = sum_intensity;
    %disp(i);
end
end

